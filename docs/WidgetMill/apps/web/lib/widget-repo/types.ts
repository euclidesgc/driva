import type {
  SpecNode,
  VersionStatus,
  WidgetIdentity,
  WidgetRecord,
  WidgetSpec,
  WidgetVersion,
} from "@widgetmill/spec";

/** Dados de um save vindos da UI; `author`/`now` são preenchidos pelo repositório. */
export interface SaveInput {
  tree: SpecNode;
  status: VersionStatus;
  propsSchema?: WidgetSpec["propsSchema"];
  message?: string;
}

/**
 * Contrato de persistência de widgets. A UI depende SÓ desta interface — a
 * implementação atual é em memória; no M3 entra uma `ApiWidgetRepository` que
 * chama o backend, sem mudar a UI.
 */
export interface WidgetRepository {
  list(): Promise<WidgetIdentity[]>;
  load(slug: string): Promise<WidgetRecord | null>;
  create(identity: WidgetIdentity): Promise<WidgetRecord>;
  editIdentity(
    slug: string,
    patch: Partial<Omit<WidgetIdentity, "kind">>,
  ): Promise<WidgetRecord>;
  saveVersion(slug: string, input: SaveInput): Promise<WidgetRecord>;
  getVersion(slug: string, version: number): Promise<WidgetVersion | null>;
  /** Soft-delete de uma versão (registrado como tombstone no histórico). */
  deleteVersion(slug: string, version: number): Promise<WidgetRecord>;
  /** Desfaz o soft-delete de uma versão. */
  restoreVersion(slug: string, version: number): Promise<WidgetRecord>;
}
