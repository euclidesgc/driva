"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import {
  latestVersion,
  type SpecNode,
  type VersionStatus,
  type WidgetIdentity,
  type WidgetRecord,
  type WidgetVersion,
} from "@widgetmill/spec";
import { widgetRepository, type WidgetRepository } from "./widget-repo";

export interface IdentityInput {
  name: string;
  slug: string;
  description: string;
}

interface WidgetSessionValue {
  record: WidgetRecord | null;
  identity: WidgetIdentity | null;
  hasIdentity: boolean;
  /** Versão de origem ao "Carregar" (próximo save vira "Restaurado de vN"). */
  editingFrom: number | null;
  toast: string | null;
  saveIdentity(input: IdentityInput): Promise<void>;
  save(status: VersionStatus, tree: SpecNode): Promise<void>;
  loadVersion(version: number): Promise<WidgetVersion | null>;
  deleteVersion(version: number): Promise<void>;
  restoreVersion(version: number): Promise<void>;
  clearEditingFrom(): void;
  clearToast(): void;
}

const Ctx = createContext<WidgetSessionValue | null>(null);

/**
 * Detém o registro do widget em edição e orquestra as ações via repositório.
 * As ações leem de refs (não do estado capturado), evitando closures velhas —
 * ex.: salvar logo após criar a identidade no mesmo gesto.
 */
export function WidgetSessionProvider({
  children,
  repository = widgetRepository,
}: {
  children: ReactNode;
  repository?: WidgetRepository;
}) {
  const [record, setRecordState] = useState<WidgetRecord | null>(null);
  const [editingFrom, setEditingFromState] = useState<number | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const recordRef = useRef<WidgetRecord | null>(null);
  const editingFromRef = useRef<number | null>(null);

  const setRecord = useCallback((r: WidgetRecord) => {
    recordRef.current = r;
    setRecordState(r);
  }, []);
  const setEditingFrom = useCallback((v: number | null) => {
    editingFromRef.current = v;
    setEditingFromState(v);
  }, []);

  const saveIdentity = useCallback(
    async (input: IdentityInput) => {
      const current = recordRef.current;
      if (!current) {
        setRecord(await repository.create({ ...input, kind: "composite" }));
        setToast("Identidade criada");
      } else {
        setRecord(await repository.editIdentity(current.identity.slug, input));
        setToast("Metadados atualizados");
      }
    },
    [repository, setRecord],
  );

  const save = useCallback(
    async (status: VersionStatus, tree: SpecNode) => {
      const slug = recordRef.current?.identity.slug;
      if (!slug) return;
      const from = editingFromRef.current;
      const message = from != null ? `Restaurado de v${from}` : undefined;
      const updated = await repository.saveVersion(slug, { tree, status, message });
      setRecord(updated);
      setEditingFrom(null);
      const v = latestVersion(updated)?.version;
      setToast(status === "published" ? `Publicado v${v}` : `Rascunho salvo v${v}`);
    },
    [repository, setRecord, setEditingFrom],
  );

  const loadVersion = useCallback(
    async (version: number) => {
      const slug = recordRef.current?.identity.slug;
      if (!slug) return null;
      const v = await repository.getVersion(slug, version);
      if (v) setEditingFrom(version);
      return v;
    },
    [repository, setEditingFrom],
  );

  const deleteVersion = useCallback(
    async (version: number) => {
      const slug = recordRef.current?.identity.slug;
      if (!slug) return;
      setRecord(await repository.deleteVersion(slug, version));
      setToast(`Versão v${version} excluída`);
    },
    [repository, setRecord],
  );

  const restoreVersion = useCallback(
    async (version: number) => {
      const slug = recordRef.current?.identity.slug;
      if (!slug) return;
      setRecord(await repository.restoreVersion(slug, version));
      setToast(`Versão v${version} restaurada`);
    },
    [repository, setRecord],
  );

  const value = useMemo<WidgetSessionValue>(
    () => ({
      record,
      identity: record?.identity ?? null,
      hasIdentity: record != null,
      editingFrom,
      toast,
      saveIdentity,
      save,
      loadVersion,
      deleteVersion,
      restoreVersion,
      clearEditingFrom: () => setEditingFrom(null),
      clearToast: () => setToast(null),
    }),
    [
      record,
      editingFrom,
      toast,
      saveIdentity,
      save,
      loadVersion,
      deleteVersion,
      restoreVersion,
      setEditingFrom,
    ],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useWidgetSession(): WidgetSessionValue {
  const ctx = useContext(Ctx);
  if (!ctx) {
    throw new Error("useWidgetSession deve estar dentro de <WidgetSessionProvider>");
  }
  return ctx;
}
