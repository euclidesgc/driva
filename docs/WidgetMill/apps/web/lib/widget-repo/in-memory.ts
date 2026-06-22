import {
  createRecord,
  deleteVersion,
  editIdentity,
  getVersion,
  restoreVersion,
  saveVersion,
  type WidgetIdentity,
  type WidgetRecord,
  type WidgetVersion,
} from "@widgetmill/spec";
import type { SaveInput, WidgetRepository } from "./types";

/**
 * Persistência **funcional em memória** (placeholder do M3): guarda os registros
 * num `Map` no nível da instância. Persiste durante a sessão; some no reload.
 * Delega toda a lógica de versão às funções puras do kernel.
 */
export class InMemoryWidgetRepository implements WidgetRepository {
  private readonly store = new Map<string, WidgetRecord>();

  constructor(private readonly author = "você") {}

  async list(): Promise<WidgetIdentity[]> {
    return [...this.store.values()].map((r) => r.identity);
  }

  async load(slug: string): Promise<WidgetRecord | null> {
    return this.store.get(slug) ?? null;
  }

  async create(identity: WidgetIdentity): Promise<WidgetRecord> {
    const record = createRecord(identity);
    this.store.set(identity.slug, record);
    return record;
  }

  async editIdentity(
    slug: string,
    patch: Partial<Omit<WidgetIdentity, "kind">>,
  ): Promise<WidgetRecord> {
    const updated = editIdentity(this.require(slug), patch);
    if (patch.slug && patch.slug !== slug) this.store.delete(slug);
    this.store.set(updated.identity.slug, updated);
    return updated;
  }

  async saveVersion(slug: string, input: SaveInput): Promise<WidgetRecord> {
    const updated = saveVersion(this.require(slug), {
      tree: input.tree,
      status: input.status,
      propsSchema: input.propsSchema,
      message: input.message,
      author: this.author,
      now: new Date().toISOString(),
    });
    this.store.set(slug, updated);
    return updated;
  }

  async getVersion(slug: string, version: number): Promise<WidgetVersion | null> {
    return getVersion(this.require(slug), version);
  }

  async deleteVersion(slug: string, version: number): Promise<WidgetRecord> {
    const updated = deleteVersion(this.require(slug), version, {
      author: this.author,
      now: new Date().toISOString(),
    });
    this.store.set(slug, updated);
    return updated;
  }

  async restoreVersion(slug: string, version: number): Promise<WidgetRecord> {
    const updated = restoreVersion(this.require(slug), version);
    this.store.set(slug, updated);
    return updated;
  }

  private require(slug: string): WidgetRecord {
    const record = this.store.get(slug);
    if (!record) throw new Error(`widget não encontrado: ${slug}`);
    return record;
  }
}
