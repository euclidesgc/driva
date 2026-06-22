/**
 * Tipos **estruturais** do modelo de dados do Puck — definidos aqui para que o
 * kernel não dependa de `@measured/puck` (mantém `packages/spec` só com zod).
 * O `apps/web` passa os dados reais do Puck, que casam com esta forma.
 */

/** Um componente Puck: `type` + `props` planas (inclui `id` e slots). */
export interface PuckComponent {
  type: string;
  props: PuckProps;
}

export interface PuckProps {
  id: string;
  [key: string]: unknown;
}

/** Documento Puck de topo. */
export interface PuckData {
  content: PuckComponent[];
  root: { props?: Record<string, unknown> };
}
