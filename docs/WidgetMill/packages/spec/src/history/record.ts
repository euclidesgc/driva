import type { WidgetSpec } from "../schema";
import type { SpecNode } from "../tree";
import { makeWidgetSpec } from "../widget/factory";
import type {
  VersionStatus,
  WidgetIdentity,
  WidgetRecord,
  WidgetVersion,
} from "./types";

/** Cria um registro vazio (sem versões) para uma identidade. */
export function createRecord(identity: WidgetIdentity): WidgetRecord {
  return { identity, versions: [] };
}

/** Uma versão foi excluída (soft-delete)? */
export const isDeleted = (v: WidgetVersion): boolean => v.deletedAt != null;

/** Próximo número de versão — monotônico (nunca reusa o de uma excluída). */
function nextVersionNumber(record: WidgetRecord): number {
  return record.versions.reduce((max, v) => Math.max(max, v.version), 0) + 1;
}

/** Última versão salva ativa (ignora excluídas), ou null. */
export function latestVersion(record: WidgetRecord): WidgetVersion | null {
  for (let i = record.versions.length - 1; i >= 0; i--) {
    const v = record.versions[i];
    if (v && !isDeleted(v)) return v;
  }
  return null;
}

/** Última versão publicada ativa (a "usada"), ou null. */
export function publishedVersion(record: WidgetRecord): WidgetVersion | null {
  for (let i = record.versions.length - 1; i >= 0; i--) {
    const v = record.versions[i];
    if (v && !isDeleted(v) && v.status === "published") return v;
  }
  return null;
}

/** Versão por número, ou null. */
export function getVersion(record: WidgetRecord, version: number): WidgetVersion | null {
  return record.versions.find((v) => v.version === version) ?? null;
}

export interface SaveVersionInput {
  tree: SpecNode;
  status: VersionStatus;
  author: string;
  now: string;
  propsSchema?: WidgetSpec["propsSchema"];
  message?: string;
}

const defaultMessage = (status: VersionStatus): string =>
  status === "published" ? "Publicado" : "Rascunho salvo";

/**
 * Anexa uma nova versão imutável (`last + 1`), montando e validando o spec.
 * Append-only: nunca remove/mutila versões anteriores.
 */
export function saveVersion(record: WidgetRecord, input: SaveVersionInput): WidgetRecord {
  const next = nextVersionNumber(record);
  const built = makeWidgetSpec({
    slug: record.identity.slug,
    name: record.identity.name,
    kind: record.identity.kind,
    version: next,
    propsSchema: input.propsSchema,
    tree: input.tree,
  });
  if (!built.ok) {
    throw new Error(`spec inválido ao salvar v${next}: ${built.error.message}`);
  }
  const version: WidgetVersion = {
    version: next,
    spec: built.spec,
    status: input.status,
    message: input.message ?? defaultMessage(input.status),
    author: input.author,
    createdAt: input.now,
  };
  return { ...record, versions: [...record.versions, version] };
}

/** Atualiza a identidade (nome/slug/descrição); não cria versão. */
export function editIdentity(
  record: WidgetRecord,
  patch: Partial<Omit<WidgetIdentity, "kind">>,
): WidgetRecord {
  return { ...record, identity: { ...record.identity, ...patch } };
}

/**
 * Exclui uma versão por **soft-delete**: ela permanece no log (tombstone) com
 * `deletedBy`/`deletedAt`, deixa de contar como ativa (latest/published a
 * ignoram) e seu número nunca é reusado. A exclusão fica, assim, registrada.
 */
export function deleteVersion(
  record: WidgetRecord,
  version: number,
  meta: { author: string; now: string },
): WidgetRecord {
  let found = false;
  const versions = record.versions.map((v) => {
    if (v.version !== version) return v;
    found = true;
    return { ...v, deletedBy: meta.author, deletedAt: meta.now };
  });
  if (!found) throw new Error(`versão não encontrada: v${version}`);
  return { ...record, versions };
}

/** Desfaz o soft-delete de uma versão (remove o tombstone; volta a contar). */
export function restoreVersion(record: WidgetRecord, version: number): WidgetRecord {
  let found = false;
  const versions = record.versions.map((v) => {
    if (v.version !== version) return v;
    found = true;
    return {
      version: v.version,
      spec: v.spec,
      status: v.status,
      message: v.message,
      author: v.author,
      createdAt: v.createdAt,
    };
  });
  if (!found) throw new Error(`versão não encontrada: v${version}`);
  return { ...record, versions };
}
