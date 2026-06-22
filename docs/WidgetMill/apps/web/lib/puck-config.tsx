import type { Config, Data } from "@measured/puck";
import {
  ALIGNMENT,
  ALIGNMENT_DIRECTIONAL,
  BORDER_STYLE,
  BOX_SHAPE,
  FONT_STYLE,
  FONT_WEIGHT,
  ICON_NAMES,
  TEXT_DECORATION,
  descriptorsByType,
  paletteCategories,
  slotKind,
  specToPuckData,
  type FieldDescriptor,
} from "@widgetmill/spec";
import { useNodeDiagnostics } from "../components/diagnostics/context";
import {
  CLEAR_OPTION,
  RequiredMark,
  borderRadiusField,
  colorField,
  dimensionField,
  edgeInsetsField,
  gradientField,
  numberField,
  sectionHeaderField,
  shadowListField,
} from "./inspector-fields";

const opts = (values: readonly unknown[]) =>
  values.map((v) => ({ label: String(v), value: v }));

/** Select de enum. Se `optional`, prefixa a opção "—" para voltar a "ausente". */
const select = (values: readonly unknown[], optional = false) => ({
  type: "select",
  options: optional ? [CLEAR_OPTION, ...opts(values)] : opts(values),
});

/** Mapeia um FieldDescriptor para um campo do Puck (ou null se tratado à parte). */
function toPuckField(d: FieldDescriptor): Record<string, unknown> | null {
  switch (d.type) {
    case "string":
      return { type: "text", label: d.key };
    case "color":
      return colorField(d.key);
    case "double":
    case "int":
      // Campo limpável: vazio vira `undefined` (some do spec), não `0`.
      return numberField(d.key);
    case "dimension":
      // Px fixo | Preencher (∞) | % largura/altura da tela.
      return dimensionField(d.key);
    case "borderRadius":
      // Uniforme | por canto (mesmo editor usado dentro do boxDecoration).
      return borderRadiusField(d.key);
    case "bool":
      // Bool opcional ganha "—" (não informado → undefined → some do spec; o
      // Flutter aplica o default). `false` é um valor legítimo (não é "branco").
      return {
        type: "radio",
        label: d.key,
        options: [
          ...(d.optional ? [CLEAR_OPTION] : []),
          { label: "sim", value: true },
          { label: "não", value: false },
        ],
      };
    case "enum":
      return { label: d.key, ...select(d.enumValues ?? [], d.optional) };
    case "iconData":
      // Seletor a partir do catálogo curado de ícones Material.
      return { label: d.key, ...select(ICON_NAMES, d.optional) };
    case "alignment":
      return { label: d.key, ...select(ALIGNMENT, d.optional) };
    case "alignmentDirectional":
      return { label: d.key, ...select(ALIGNMENT_DIRECTIONAL, d.optional) };
    case "edgeInsets":
      // Seletor de modo: Todos / Simétrico / Por lado.
      return edgeInsetsField(d.key);
    case "textStyle":
      // Subcampos de enum são opcionais (sem default) → opção "—" para limpar.
      return {
        type: "object",
        label: d.key,
        objectFields: {
          fontSize: numberField("fontSize"),
          fontWeight: select(FONT_WEIGHT, true),
          fontStyle: select(FONT_STYLE, true),
          color: colorField("color"),
          fontFamily: { type: "text" },
          letterSpacing: numberField("letterSpacing"),
          wordSpacing: numberField("wordSpacing"),
          height: numberField("height"),
          decoration: select(TEXT_DECORATION, true),
        },
      };
    case "boxDecoration":
      return {
        type: "object",
        label: d.key,
        objectFields: {
          color: colorField("color"),
          gradient: gradientField("gradient"),
          borderRadius: borderRadiusField("borderRadius"),
          shape: select(BOX_SHAPE, true),
          border: {
            type: "object",
            objectFields: {
              color: colorField("color"),
              width: numberField("width"),
              style: select(BORDER_STYLE, true),
            },
          },
          boxShadow: shadowListField("boxShadow"),
        },
      };
    case "buttonStyle":
      return {
        type: "object",
        label: d.key,
        objectFields: {
          backgroundColor: colorField("backgroundColor"),
          foregroundColor: colorField("foregroundColor"),
          padding: edgeInsetsField("padding"),
          elevation: numberField("elevation"),
          borderRadius: borderRadiusField("borderRadius"),
          textStyle: {
            type: "object",
            objectFields: {
              fontSize: numberField("fontSize"),
              fontWeight: select(FONT_WEIGHT, true),
              color: colorField("color"),
            },
          },
          side: {
            type: "object",
            objectFields: {
              color: colorField("color"),
              width: numberField("width"),
              style: select(BORDER_STYLE, true),
            },
          },
        },
      };
    // Editor de ações (actionList) é um follow-up (T2.6).
    case "actionList":
    default:
      return null;
  }
}

/**
 * Monta os campos do Puck para um primitivo. Agrupa por `group` (na ordem de
 * primeira aparição no descriptor) e insere um cabeçalho de seção por grupo —
 * dando ao Inspector a organização em seções (estilo FlutterFlow). Cabeçalhos
 * só aparecem quando há ≥2 grupos com campos (evita ruído em primitivos simples).
 */
function buildFields(type: string): Record<string, unknown> {
  const descriptors = descriptorsByType[type] ?? [];

  // Ordem dos grupos = primeira aparição (estável).
  const groupOrder = new Map<string, number>();
  for (const d of descriptors) {
    const g = d.group ?? "";
    if (!groupOrder.has(g)) groupOrder.set(g, groupOrder.size);
  }

  // (descriptor, field) na ordem por grupo; descarta os sem campo (ex.: actionList).
  const built = descriptors
    .map((d, i) => ({ d, i, field: toPuckField(d) }))
    .filter(
      (x): x is { d: FieldDescriptor; i: number; field: Record<string, unknown> } =>
        x.field !== null,
    )
    .sort((a, b) => {
      const ga = groupOrder.get(a.d.group ?? "") ?? 0;
      const gb = groupOrder.get(b.d.group ?? "") ?? 0;
      return ga - gb || a.i - b.i;
    });

  const renderedGroups = new Set(built.map((x) => x.d.group).filter(Boolean));
  const useHeaders = renderedGroups.size >= 2;

  const fields: Record<string, unknown> = {};
  const headersDone = new Set<string>();
  for (const { d, field } of built) {
    if (useHeaders && d.group && !headersDone.has(d.group)) {
      headersDone.add(d.group);
      fields[`__section_${d.group}`] = sectionHeaderField(d.group);
    }
    // Marca de obrigatório, uniforme para qualquer tipo de campo (o Puck
    // renderiza `labelIcon` no slot de ícone do label).
    if (d.required) field.labelIcon = <RequiredMark />;
    fields[d.key] = field;
  }

  const kind = slotKind(type);
  if (kind) fields[kind] = { type: "slot" };
  return fields;
}

const boxStyle: React.CSSProperties = {
  border: "1px dashed #b0bec5",
  borderRadius: 6,
  padding: 8,
  margin: 2,
  minHeight: 24,
};
const tagStyle: React.CSSProperties = {
  fontSize: 10,
  color: "#607d8b",
  textTransform: "uppercase",
  letterSpacing: 0.5,
};

const sevBorder: Record<string, string> = {
  error: "2px solid #b3261e",
  warning: "2px solid #e6a700",
};

/** Render placeholder no canvas do Puck (a fidelidade real é o preview Flutter). */
function renderFor(type: string) {
  const kind = slotKind(type);
  return (props: Record<string, unknown>) => {
    const diags = useNodeDiagnostics();
    const id = typeof props.id === "string" ? props.id : undefined;
    const sev = id ? diags.get(id) : undefined;
    const Slot = kind ? (props[kind] as undefined | (() => React.ReactNode)) : undefined;
    const caption =
      type === "text"
        ? String(props.data ?? "")
        : type === "button"
          ? String(props.label ?? "Button")
          : type;
    return (
      <div
        style={{ ...boxStyle, border: sev ? sevBorder[sev] : boxStyle.border }}
        data-type={type}
        title={sev ? `${sev === "error" ? "Erro" : "Aviso"} de montagem` : undefined}
      >
        <div style={tagStyle}>{type}</div>
        {type === "text" || type === "button" ? <div>{caption}</div> : null}
        {typeof Slot === "function" ? <Slot /> : null}
      </div>
    );
  };
}

const types = Object.keys(descriptorsByType);

/**
 * Props default (valores padrão do Flutter) por primitivo — derivadas dos
 * descriptors. O Puck pré-preenche o componente recém-adicionado com elas, então
 * o usuário **vê** no Inspector e na aba Spec o que está de fato configurado
 * (em vez de um padrão invisível). A omissão é higienização opcional no export.
 */
function defaultPropsFor(type: string): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const d of descriptorsByType[type] ?? []) {
    if (d.default !== undefined) out[d.key] = d.default;
  }
  return out;
}

const components: Record<string, unknown> = {};
for (const type of types) {
  components[type] = {
    label: type,
    fields: buildFields(type),
    defaultProps: defaultPropsFor(type),
    render: renderFor(type),
  };
}

/** Categorias colapsáveis da paleta (derivadas do kernel — ver `paletteCategories`). */
const categories = Object.fromEntries(
  paletteCategories(types).map((c) => [
    c.name,
    { title: c.title, components: c.components, defaultExpanded: true },
  ]),
);

// `root: { fields: {} }` remove o campo "title"/"Page" padrão do Puck. Aqui não há
// conceito de "página" nem nome de página: o que importa é o componente, cuja
// identidade (nome/slug) é tratada fora do canvas (sessão + diálogo de metadados).
export const config = {
  root: { fields: {} },
  categories,
  components,
} as unknown as Config;

const SAMPLE_NODE = {
  type: "container",
  props: { padding: { all: 16 } },
  child: {
    type: "column",
    props: { spacing: 8, crossAxisAlignment: "start" },
    children: [
      {
        type: "text",
        props: { data: "Olá, WidgetMill", style: { fontSize: 20, fontWeight: "w700" } },
      },
      { type: "text", props: { data: "Arraste primitivos e veja o preview." } },
    ],
  },
};

export const INITIAL_DATA = specToPuckData(SAMPLE_NODE) as unknown as Data;
