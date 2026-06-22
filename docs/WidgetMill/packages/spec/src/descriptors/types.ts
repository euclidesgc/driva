/** Tipos de campo que o Inspector sabe renderizar (`type → componente`). */
export const FIELD_TYPES = [
  "string",
  "double",
  "int",
  "bool",
  "color",
  "enum",
  // Ícone Material (seletor a partir do catálogo curado ICON_NAMES).
  "iconData",
  // Dimensão: px fixo OU token relativo (preencher / % de tela). Editor com modos.
  "dimension",
  "edgeInsets",
  // BorderRadius avulso (uniforme | por canto) — reusa o editor do boxDecoration.
  "borderRadius",
  "textStyle",
  "boxDecoration",
  // Estilo de botão (cores, elevação, raio, borda, textStyle) — editor agrupado.
  "buttonStyle",
  "alignment",
  "alignmentDirectional",
  "actionList",
] as const;

export type FieldType = (typeof FIELD_TYPES)[number];

/** Descreve um campo editável de um primitivo (gera o form do Inspector). */
export interface FieldDescriptor {
  key: string;
  type: FieldType;
  label?: string;
  group?: string;
  enumValues?: readonly string[];
  /**
   * Campo **obrigatório** no schema (sem default e não-opcional). O Inspector
   * marca com um asterisco. Espelha o schema Zod — manter em sincronia.
   */
  required?: boolean;
  /**
   * Campo **opcional sem default**, i.e. pode ser removido/ficar ausente. Só é
   * consumido por campos de seleção (`enum`/`alignment`), onde habilita a opção
   * "—" para voltar a "não informado" (campos de texto/número já representam
   * vazio nativamente, então não precisam da marca).
   */
  optional?: boolean;
  /**
   * Valor padrão do Flutter para a prop. **Pré-preenchido ao adicionar o
   * componente** (via `defaultProps` do Puck) para que o usuário veja, no
   * Inspector e na aba Spec, o que está de fato configurado. A omissão desses
   * padrões é uma higienização opcional feita só no export pro Dart (o renderer
   * já aplica o mesmo default na ausência).
   */
  default?: unknown;
  /** Esconde o campo conforme o estado atual das props (ex.: regras do Flutter). */
  hidden?: (props: Record<string, unknown>) => boolean;
}
