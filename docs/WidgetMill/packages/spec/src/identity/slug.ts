// Faixa Unicode dos diacríticos combinantes (acentos) após a normalização NFD.
const DIACRITICS = /[̀-ͯ]/g;

/**
 * Deriva um slug estável a partir de um nome: minúsculas, sem acentos,
 * separadores não-alfanuméricos colapsados em `_` e pontas aparadas.
 * Ex.: `"Botão Primário" → "botao_primario"`.
 */
export function slugify(name: string): string {
  return name
    .normalize("NFD")
    .replace(DIACRITICS, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_") // não-alfanumérico → separador
    .replace(/^_+|_+$/g, ""); // apara pontas
}
