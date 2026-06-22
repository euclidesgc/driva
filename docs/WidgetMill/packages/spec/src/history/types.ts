import type { WidgetSpec } from "../schema";

/** Status de workflow de uma versão (espelha o modelo do Squidex). */
export type VersionStatus = "draft" | "published";

/** Identidade do widget (metadados estáveis entre versões). */
export interface WidgetIdentity {
  slug: string;
  name: string;
  description: string;
  kind: "composite";
}

/** Snapshot imutável de uma versão publicada/salva (event-sourced). */
export interface WidgetVersion {
  version: number;
  spec: WidgetSpec;
  status: VersionStatus;
  message: string;
  author: string;
  createdAt: string;
  /** Soft-delete: preenchidos quando a versão é excluída (fica como tombstone). */
  deletedBy?: string;
  deletedAt?: string;
}

/**
 * Registro de um widget: identidade + log append-only de versões.
 * O histórico/auditoria é a própria lista de versões (como no Squidex);
 * a "versão usada" é derivada (última `published`), não armazenada.
 */
export interface WidgetRecord {
  identity: WidgetIdentity;
  versions: WidgetVersion[];
}
