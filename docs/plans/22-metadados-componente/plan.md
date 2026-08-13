# plan.md — Item 22: Metadados e vitrine dos componentes

> Documento de planejamento. Dono na execução: **especialista-apresentacao**. Base: `docs/roadmap.md` › Marco 8.
> **Precedência dura: itens 20 e 21.** Sem componente construído e usável, não há o que apresentar.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**.

## 1. Objetivo e recorte

Os itens 19–21 entregam a mecânica. Este entrega a **cara**: na aba Componentes do editor (item 21 F2), a lista precisa parecer a paleta de widgets — ícone reconhecível, nome curto, agrupamento por categoria — e não uma lista de texto. É o item que faz componente parecer parte do produto em vez de um anexo.

**Entra:**
1. Metadados do componente: **ícone** (do conjunto curado) ou **imagem de capa**, **rótulo curto** e **descrição de uma linha**.
2. Escolha desses metadados no momento de salvar/criar o componente.
3. A aba Componentes agrupada por categoria, com busca, no padrão visual da paleta de widgets.
4. Preview do componente no hover/tooltip da vitrine.

**Fica fora:** biblioteca de componentes compartilhada entre projetos, marketplace, versionamento visual (diff), thumbnail gerado automaticamente do canvas (registrado em §7 — é a evolução óbvia, mas exige renderização off-screen e upload).

## 2. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `curatedIconNames` exportado pelo `sdui_flutter` e o `IconEditor` do Inspector (`FieldKind.iconName`) | `sdui_flutter/lib/sdui_flutter.dart:17`, `.../prop_field/icon_editor.dart` | **O seletor de ícone já existe pronto** — o formulário do componente o reusa, não escreve outro. |
| `WidgetPalette` / `PaletteTile` / `PaletteItem` — agrupamento por `WidgetCategories.inPaletteOrder`, busca, arraste | `.../widgets/widget_palette/` | **É o gabarito visual literal** da vitrine de componentes. Copiar o comportamento, não a implementação (ver F3). |
| Upload de imagem com pipeline seguro (magic bytes, allowlist, reencode, UUID) + `StorageService` por prefixo | `backend/src/projects/image-pipeline.ts`, `backend/src/storage/` | Se houver capa de componente, **reusa a pipeline inteira**; o `prefix` vira `<projectId>/componentes`. |
| `CoverPicker`/`CoverPreview`/`CoverPlaceholder` + `ImagePicker`/`ImageDropZone` (web) da feature 09 | `projects_module/.../project_form/`, `.../widgets/image_picker*.dart` | Se houver capa, **reusa o seletor de imagem inteiro** — ele já resolve web vs stub. |
| `Content.description` (já existe na tabela) | `backend/prisma/schema.prisma:71` | Serve como a descrição de uma linha — **campo novo desnecessário**. |
| `Category` + a árvore compartilhada (item 19 D3) | — | O agrupamento da vitrine é por categoria. |

## 3. Decisões

**D1 — Ícone primeiro; capa é opcional e vem depois.**
Um ícone do conjunto curado + categoria já resolve reconhecimento na vitrine, custa **zero backend** (é uma string no spec ou numa coluna) e reusa o `IconEditor` pronto. Capa em imagem exige upload, storage, serving e cache — tudo já existente (feature 09), mas é uma fase inteira a mais.
**Recomendação:** F1+F3 (ícone) entregam o item; F2 (capa) é opcional e pode virar polimento futuro.

**D2 — Os metadados moram no spec, não em colunas novas.**
`ContentSpec` ganha `final ComponentMeta? meta` — gravado no JSON, omitido quando nulo (mesmo padrão de `safeArea`/`params`). Motivo: são metadados **de apresentação do componente**, viajam com ele em export/import, e evitam migração de banco. `description` continua na coluna (já existe e alimenta a busca).
Contra-argumento considerado: filtrar/ordenar por ícone exigiria varrer JSONB — mas **ninguém filtra por ícone**. Decisão mantida.

**D3 — Rótulo curto é separado do nome.**
`name` ("Cabeçalho padrão com busca e avatar") é o nome de gestão, aparece na lista da tela do projeto. `meta.label` ("Cabeçalho") é o que cabe embaixo do ícone na vitrine. Sem essa separação, ou o nome fica críptico ou a vitrine fica ilegível. `label` vazio → cai para `name` truncado.

## 4. Fases

### F1 — Kernel + formulário: ícone, rótulo e descrição

- **`sdui_core/lib/src/model/component_meta.dart`** (novo) — `class ComponentMeta extends Equatable {final String label; final String iconName; final String? coverKey;}` + `toJson`/`fromJson`. `coverKey` já nasce no modelo (usado só se a F2 acontecer) — evita mexer no kernel duas vezes.
- **`sdui_core/lib/src/model/content_spec.dart`** — `final ComponentMeta? meta;` no `copyWith` (com função-getter, pelo padrão de campo nullable do projeto), `props` e `toJson` (`if (meta != null)`).
- **`sdui_core/lib/src/schema/content_schema.dart`** — parse tolerante do bloco `meta`; `iconName` fora do conjunto curado **não** é erro (o kernel é Dart puro e não conhece a lista do Flutter — a validação de ícone é do editor). Erro só de forma.
- **`contents_module/.../content_form_dialog.dart`** — quando o `kind` é `component` (item 19), o formulário mostra rótulo curto + seletor de ícone (`IconEditor` reusado) + descrição.
- **`editor_module`** — no editor do componente, os mesmos campos ficam acessíveis pelo Inspector no modo página (item 20 F1), para não obrigar a voltar à lista só para trocar o ícone.

**Aceite:** criar componente com ícone e rótulo; reabrir e ver preenchido; spec sem `meta` continua válido.

### F2 — Capa em imagem  **[opcional; ∥ com F3]**

Só se a decisão do humano pedir (§6). Reusa: `image-pipeline.ts` com `prefix: '<projectId>/componentes'`, `StorageService`, a rota de mídia (`/v1/media/:key`, item 27 D3) e o `CoverPicker` do `projects_module`.
> **Dependência real:** a rota `/v1/media/:key` nasce no item 27 (ou no 26). Se nenhum dos dois tiver acontecido, a capa seria servida por uma rota nova só para isso — **não vale**. **Regra: F2 só depois do item 27.**

### F3 — A vitrine na aba Componentes

- **`.../widgets/component_library/component_gallery.dart`** (novo) — substitui a lista simples da F2 do item 21: grade de cards agrupados por categoria, com busca (mesmo `SearchField` de `core/widgets/input/`).
- **`.../widgets/component_library/component_card.dart`** — ícone (ou capa), rótulo, tooltip com a descrição. **Arrastável, com o mesmo `DragPayload` da F2 do item 21** — o comportamento de arraste não muda, só a aparência.
- **`.../widgets/component_library/component_preview_tooltip.dart`** — no hover, um preview pequeno renderizado com `SduiView` do root do componente, dentro de `FittedBox` + `RepaintBoundary` e **construído só no hover** (não montar 30 renderers ao abrir a aba — regra de rebuild mínimo).

> **Não copiar o código do `WidgetPalette`.** Se a estrutura for a mesma, **extrair** o esqueleto comum (agrupamento + busca + grade) para `editor_module/presentation/editor/widgets/palette_shell/` e usá-lo nos dois. Duplicar a paleta é a forma mais provável de este item envelhecer mal.

### F4 — Testes
Golden da vitrine (com e sem ícone), widget test da busca e do agrupamento, teste do fallback `label` vazio → `name`, e round-trip de `meta` no schema.

## 5. Mapa de paralelismo

```
F1 ──┬─► F3 ──► F4
     └─► F2 (opcional, exige item 27)
```

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 21 — substituição planejada:** a `ComponentList` simples da F2 de lá é **trocada** pela `ComponentGallery` daqui. Isso é intencional e está declarado nos dois planos: o item 21 entrega funcional, o 22 entrega apresentável. **Não** construir a lista do 21 de um jeito que impeça a troca (manter o arraste isolado do visual).
- **Item 27 (storage) — dependência da F2** (rota de mídia). Registrada.
- **Item 24 (publicação)** — `meta` viaja na versão publicada. Inofensivo (o runtime ignora), mas conta bytes; se incomodar, a expansão do item 21 D2 pode remover `meta` da árvore publicada. **Anotado no plano 21 como afinação futura, não obrigação.**
- **Item 9 (catálogo)** — a extração do `palette_shell` (F3) beneficia a paleta de widgets. Anotado no plano 9.

## 7. Perguntas para o humano

1. **Capa em imagem vale a fase (F2)?** Recomendo começar só com ícone e ver se falta.
2. **Thumbnail automático** (renderizar o componente off-screen e salvar como imagem) é o que o FlutterFlow faz e é bonito — mas custa render off-screen + upload + invalidação a cada publicação. Fica para depois?
3. **A vitrine deve mostrar componentes não publicados?** Assumido: **sim, com selo de rascunho** — mas inserir um não publicado num conteúdo bloqueia o publish do conteúdo (item 21 D4). Alternativa: esconder os não publicados (mais simples, menos descobrível).
