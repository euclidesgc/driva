import { slugify } from "./slug";

describe("slugify", () => {
  it("minúsculas com underscore como separador", () => {
    expect(slugify("Botão Primário")).toBe("botao_primario");
  });

  it("remove acentos/diacríticos", () => {
    expect(slugify("Ação ÀÉÍÕÇ")).toBe("acao_aeioc");
  });

  it("colapsa separadores e apara as pontas", () => {
    expect(slugify("  Card --- Top  ")).toBe("card_top");
  });

  it("descarta caracteres não-alfanuméricos", () => {
    expect(slugify("Preço (R$) 50%")).toBe("preco_r_50");
  });

  it("string já em slug permanece", () => {
    expect(slugify("primary_button")).toBe("primary_button");
  });

  it("string vazia → vazia", () => {
    expect(slugify("")).toBe("");
  });
});
