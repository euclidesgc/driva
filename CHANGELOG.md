# Changelog

## [0.1.0] — 2026-07-02 · I1: Módulo Página

- **sdui_core**: kernel do spec (specVersion 1) — `SduiNode` com id, `PageSpec` (página = fragmento com `screenTarget`, root sempre `column`), `parsePageSpec` (zard + validação recursiva contra o catálogo e slots), catálogo de 14 primitivos com descriptors, `tree_ops` puras.
- **sdui_flutter**: renderer com registry `type → builder` para os 14 primitivos, `SduiView`, `nodeWrapper` (gancho de seleção do editor), fallback amigável para tipo desconhecido.
- **driva_editor**: lista de páginas (grid, criar/excluir) e o editor de 3 colunas — paleta com busca e drag-and-drop, árvore com reordenação/aninhamento, canvas com moldura de dispositivo (3 presets + zoom) renderizando o preview com o renderer real, inspector 100% derivado do catálogo, salvar explícito (botão + Ctrl+S) com indicador de estado, Delete remove o bloco selecionado. Tema claro extraído do protótipo (laranja `#E8602C`), tipografia **Public Sans** empacotada (pesos 400/500/600/700).
- **backend**: NestJS + Prisma + Postgres (porta 5433) com `/v1/pages` (CRUD de specs JSONB), escopo por `x-project-id`, validação de DTO e de `specVersion`.
- **Método**: time de IA (9 agentes + 5 skills em `.claude/`), CLAUDE.md com as regras do livro, docs vivas em `docs/feature-modulo-pagina/`.
- Testes: 57 (30 kernel + 7 renderer + 20 editor), `flutter analyze` zero issues.
