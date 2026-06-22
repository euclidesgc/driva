import { descriptorsByType } from "./catalog";

/** Uma categoria da paleta do editor (renderizada como seção colapsável). */
export interface PaletteCategory {
  /** Chave estável (usada como key da categoria no Puck). */
  name: string;
  /** Rótulo exibido na lista lateral. */
  title: string;
  /** Tipos de primitivo desta categoria, na ordem de exibição. */
  components: string[];
}

/** Agrupamento dos primitivos na paleta — fonte única de verdade. */
export const COMPONENT_CATEGORIES: readonly PaletteCategory[] = [
  {
    name: "layout",
    title: "Layout",
    components: [
      "container",
      "row",
      "column",
      "wrap",
      "stack",
      "center",
      "align",
      "padding",
      "sizedBox",
      "card",
      "divider",
    ],
  },
  {
    name: "flex",
    title: "Flex & Posição",
    components: ["expanded", "flexible", "spacer", "positioned"],
  },
  {
    name: "sizing",
    title: "Dimensão & Efeitos",
    components: [
      "aspectRatio",
      "fractionallySizedBox",
      "opacity",
      "safeArea",
      "singleChildScrollView",
    ],
  },
  {
    name: "content",
    title: "Conteúdo",
    components: ["text", "image", "icon"],
  },
  {
    name: "interaction",
    title: "Interação",
    components: ["button", "gestureDetector"],
  },
];

/**
 * Resolve as categorias para um conjunto de tipos: descarta tipos ausentes e
 * joga qualquer primitivo não-categorizado em "Outros" (anti-drift — nada some
 * da paleta se um novo primitivo for adicionado sem categoria).
 */
export function paletteCategories(
  types: readonly string[] = Object.keys(descriptorsByType),
): PaletteCategory[] {
  const known = new Set(types);
  const seen = new Set<string>();
  const result: PaletteCategory[] = [];

  for (const cat of COMPONENT_CATEGORIES) {
    const present = cat.components.filter((t) => known.has(t));
    if (present.length === 0) continue;
    present.forEach((t) => seen.add(t));
    result.push({ name: cat.name, title: cat.title, components: present });
  }

  const rest = types.filter((t) => !seen.has(t));
  if (rest.length > 0) {
    result.push({ name: "other", title: "Outros", components: [...rest] });
  }

  return result;
}
