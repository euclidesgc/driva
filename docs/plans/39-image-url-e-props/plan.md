# plan.md — Item 39: Widget `image` — a URL aparece, e o editor de propriedades cresce

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 2 (item 9, track contínuo) — **mais um bugfix que pode sair antes**.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend** (o spec é JSONB opaco).
> **0-dep.** Nasce de relato do dev humano no uso real (2026-08-15).

> ✅ **Numeração e indexação resolvidas (2026-08-15).** A pasta nasceu como `32-`, colidindo com o item 32 do roadmap; foi renomeada para **39**. A recomendação do plano foi acatada **em conteúdo**: o item aparece no roadmap com as duas naturezas explícitas — a **F1 é defeito** (sai como `bugfix/*`) e a **F2 é o "Incremento 4: `image` abrangente" do item 9**, listado também como sub-bullet lá. O número 39 ficou só como endereço do plano. **Decisão do humano:** 38 e 39 saem **antes** do item 24.

## 1. Objetivo e recorte

Relato: _"O componente de imagem precisa melhorar os editores de propriedades e uma vez que eu informei a url de uma imagem na propriedade ela deveria ser exibida, atualmente não está exibindo."_

São **duas coisas diferentes** e o plano as separa, porque uma é defeito e a outra é catálogo:

1. **Bug (F1).** A imagem não aparece **e o editor não diz por quê** — a falha de carregamento é pixel a pixel idêntica ao estado "sem URL".
2. **Incremento de catálogo (F2).** O `image` tem 4 propriedades; o `container` tem 12. Falta o básico que qualquer editor visual oferece.

**Fica fora:** upload de imagem pelo editor (depende do item 27, storage); `image` a partir de asset local do app cliente; blurhash/placeholder por imagem; `Image.memory`/base64; `svg`.

## 2. Causa confirmada (levantamento de 2026-08-15)

**As duas primeiras suspeitas estão mortas.** A prop **chega** e o builder **lê**:

- Descriptor: `PropField(key: 'src', kind: FieldKind.string, label: 'URL da imagem', isRequired: true)` — `packages/sdui_core/lib/src/catalog/widget_catalog.dart:317-323`.
- Builder: `final src = (p['src'] ?? '').toString();` — `packages/sdui_flutter/lib/src/builders/image.dart:10`. Mesma chave, mesmo tipo. Registrado no registry (`default_registry.dart:36`).
- O campo de texto comita **a cada tecla**, sem `onSubmitted` nem debounce: `.../prop_field/string_editor.dart:47-49` → `inspector_prop_list.dart:111-112` → `inspector_area.dart:30` → `EditorCubit.updateProps` (`editor_cubit.dart:324`). Clicar fora **não perde** o valor.
- O canvas usa o renderer real (`.../canvas/preview_surface.dart:96` → `SduiView.content`), e nada o cobre: as quatro decorações de `SelectableNodeSurface` são `DecorationPosition.foreground`/`CustomPaint(foregroundPainter:)` sobre um `Stack(fit: StackFit.passthrough)` (`.../canvas/selectable_node_surface.dart:29-76`).

**O defeito real é este — `packages/sdui_flutter/lib/src/builders/image.dart`:**

```dart
if (src.isEmpty) {                                        // :14
  return SizedBox(width: width ?? 80, height: height ?? 80,
    child: const ColoredBox(color: Color(0x22000000)));   // :15-19
}
return Image.network(src, width: width, height: height, fit: boxFitFrom(p['fit']),
  errorBuilder: (_, _, _) => SizedBox(width: width ?? 80, height: height ?? 80,
    child: const ColoredBox(color: Color(0x22000000))),   // :26-30
);
```

**O `errorBuilder` desenha exatamente o mesmo quadrado cinza do caso "sem URL"** — e não há `loadingBuilder`. Do ponto de vista do usuário, "falhou" e "não preenchi" são o **mesmo pixel**. Ele digita a URL, o quadrado cinza continua lá, e a conclusão é "não está exibindo".

**Por que a falha acontece, na maior parte dos casos: CORS no Flutter Web.** O builder não passa `webHtmlElementStrategy`, então vale o default `WebHtmlElementStrategy.never` (`flutter/lib/src/widgets/image.dart:455`, doc em `:400-423`). Na implementação web isso cai em `loadViaDecode()` (`flutter/lib/src/painting/_network_image_web.dart:168-170`), que busca os **bytes** por `XMLHttpRequest` (`:190`) — sujeito à política de mesma origem. Um `<img>` do HTML não seria.

**Verificado empiricamente (2026-08-15), e é o dado que fecha o caso:**

| URL | Resposta | Carrega em `<img>` | Carrega no `Image.network` web hoje |
| --- | --- | --- | --- |
| `www.google.com/images/branding/googlelogo/...png` | `200`, `cross-origin-resource-policy: cross-origin`, **sem `access-control-allow-origin`** | sim | **não** |
| `picsum.photos`, `images.unsplash.com`, `cdn.pixabay.com`, `upload.wikimedia.org` | `access-control-allow-origin: *` | sim | sim |

Ou seja: URLs de CDN de banco de imagens funcionam; **uma URL copiada com "copiar endereço da imagem" de um site qualquer, não** — e falha em silêncio. É comportamento de plataforma, não bug nosso, mas **é nosso o dever de mostrar e de contornar** (o próprio doc do Flutter aponta a saída, `image.dart:409-412`).

**Segunda causa silenciosa, independente da primeira — `width: 0` some com a imagem.** O editor `doubleNum` comita a cada tecla e **não aplica `field.min`** (`.../prop_field/number_editor.dart:55-62`; o `min: 0` de `widget_catalog.dart:329` só alimenta o `Slider`, `:80-86`, que nem aparece porque `image` não define `max`). Digitar `0` em Largura produz `Image.network(width: 0)` — e o placeholder também, porque `width ?? 80` vira `0`. Contraste: o `DimensionEditor` **clampa** contra `field.min` (`.../prop_field/dimension_editor.dart:73-77`). Entrada inválida (`abc`) é descartada em silêncio, deixando o campo dessincronizado do estado.

**O que não deu para determinar:** qual URL o dev usou. Por isso a F1 não escolhe uma causa — ela **torna toda causa visível** (carregando / falhou / vazio deixam de ser o mesmo pixel) **e** remove a classe CORS. Qualquer que tenha sido o caso, sai resolvido ou explicado.

## 3. Precedências — o que já existe

| O que | Onde | Uso |
| --- | --- | --- |
| `buildImage` + registry | `sdui_flutter/lib/src/builders/image.dart:8`, `.../default_registry.dart:36` | Alvo da F1. |
| `SduiDimensionBox` (px / % / "preenche", min/max, `LayoutBuilder`) | `sdui_flutter/lib/src/layout/sdui_dimension_box.dart:13` | O que `image` passa a usar para width/height (D2), como o `container` já faz (`builders/container.dart:29-35`). |
| `parseDouble` (só `num`), `resolveDimension`, `parseColor`, `parseBorderRadius`, `parseEdgeInsets` | `sdui_flutter/lib/src/parsing/parsers.dart:45,53,9,79` | `parseDouble` é justamente o que **não** entende `"100%"`. |
| `boxFitFrom` (default `contain`), `alignmentFrom` | `sdui_flutter/lib/src/parsing/enums.dart:79,62` | `fit` já existe; `alignment` entra na F2. |
| `container` com 12 props, incluindo `borderRadius`/`borderColor`/`borderWidth` | `sdui_core/lib/src/catalog/widget_catalog.dart` (bloco `'container'`) | O gabarito de "descriptor completo". |
| Golden do `image` **sem `src`** (renderiza o placeholder) | `sdui_flutter/test/renderer_golden_test.dart:55` | Regravar ao mudar o placeholder (risco R1). |
| `NumberEditor` sem clamp × `DimensionEditor` com clamp | `.../prop_field/number_editor.dart:55-62` × `.../prop_field/dimension_editor.dart:73-77` | A dívida que a F1 paga. |
| `PropField.helpText` existe no modelo, é preenchido, **e não é renderizado em lugar nenhum** | `sdui_core/lib/src/catalog/prop_field.dart:16,39`; preenchido em `safe_area_descriptor.dart:21,64`; `grep helpText apps/driva_editor/lib` = **zero** | A F2 o acende — é onde a explicação de URL pública vai morar. |
| `PropFieldShell` (rótulo, `*` de obrigatório) | `.../prop_field/prop_field_shell.dart:56-57` | Onde o `helpText` entra. |
| `isRequired` **não valida nada** (só asterisco e trava o reset) | `prop_field_editor.dart:50`, `prop_field_shell.dart:56-57` | Registrado; fora de escopo (§7). |

## 4. Decisões de design travadas

### D1 — Vazio, carregando e falhou passam a ser **três** estados visualmente distintos.

É a correção que faz o defeito parar de existir, independentemente da causa. O estado de falha carrega **o motivo em texto** (`Semantics` + tooltip), não só um ícone — cor nunca é o único sinal (CLAUDE.md, acessibilidade).

### D2 — `webHtmlElementStrategy: WebHtmlElementStrategy.fallback`.

Tenta primeiro pelos bytes (rápido, compõe com o resto da árvore Flutter); se falhar — que é o caso CORS —, cai para `<img>` num platform view, que ignora a política de mesma origem. É exatamente o remédio que o Flutter documenta para "images hosted on a CDN or from arbitrary URLs" (`flutter/lib/src/widgets/image.dart:409-412`).

**Preço, registrado de propósito** (`image.dart:414-421` + `_network_image_web.dart:142-154`): no caminho de fallback a imagem vira platform view — desempenho pior, **não é capturável por screenshot/golden**, `loadingBuilder` não reporta progresso (é `OneFrameImageStreamCompleter`), e `opacity`/`colorBlendMode`/`repeat`/filtros são ignorados (nenhum deles é usado pelo `buildImage`). **Só afeta web** — no app cliente em celular não existe CORS e o caminho de bytes sempre vence.

**Alternativa descartada:** proxy de imagem no backend (`/v1/media/proxy?url=`), que devolveria a imagem com `Access-Control-Allow-Origin` e manteria tudo na camada Flutter. É superior tecnicamente e **é um vetor de SSRF** — exige CISO, allow-list e custo de banda. Fica registrado como evolução (§7), não como fatia.

### D3 — `width`/`height` do `image` migram de `doubleNum` para `dimension`.

"Largura 100%" é o pedido mais comum de uma imagem e hoje é impossível. `DimensionValue.parse` aceita `num` como `PixelDimension`, então **todo spec já salvo continua válido sem migração** — e isso vira teste explícito. O builder passa a usar `SduiDimensionBox`, exatamente como `builders/container.dart:29-35`.

De carona, isso resolve o `width: 0` pelo caminho certo: o `DimensionEditor` clampa contra `field.min` (`dimension_editor.dart:73-77`), coisa que o `NumberEditor` não faz.

### D4 — O placeholder do `sdui_flutter` é chrome de autoria, e isso é uma dívida assumida.

`buildImage` desenha um quadrado cinza quando não há `src` — no app do cliente isso é um quadrado cinza em produção. É o que hoje torna o nó selecionável no canvas, então **fica**; mas é um `SduiAuthoringScope` que não existe. Registrado em §7; não é fatia deste item.

### D5 — A F1 sai sozinha, antes da F2.

São arquivos disjuntos (F1: `builders/image.dart` + um editor do inspector; F2: catálogo + inspector genérico). A F1 é curta, é defeito, e todo dia que fica no ar o produto parece quebrado.

## 5. Fases

### F1 — Bug: a imagem aparece, ou o editor explica por que não **[base]** **[sub-agente: especialista-infra]**

**Mergeável sozinha. É o candidato a `bugfix/*` curto.**

- **`packages/sdui_flutter/lib/src/builders/image.dart`** —
  - `webHtmlElementStrategy: WebHtmlElementStrategy.fallback` (D2).
  - `loadingBuilder` → estado "carregando" próprio.
  - `errorBuilder` → estado "falhou" **visualmente distinto** do vazio, com ícone + borda + `Semantics`/tooltip trazendo o motivo e a URL (D1).
- **Widgets novos, arquivo próprio cada um** (Gates 1 e 3; a exceção de Gate 1 cobre a *função builder* do registry, não os widgets que ela monta): `sdui_flutter/lib/src/builders/image/image_empty_box.dart`, `.../image_loading_box.dart`, `.../image_error_box.dart`. Estilo por token, sem `Color(0x…)` cru (Gate 4) — hoje o `0x22000000` está hardcoded em duas cópias (`image.dart:18,29`).
- **`apps/driva_editor/lib/.../prop_field/number_editor.dart`** — clampar contra `field.min`/`field.max` como o `DimensionEditor` já faz (`dimension_editor.dart:73-77`), e **sinalizar** entrada inválida em vez de descartá-la calada (`number_editor.dart:55-62`). Vale para todo `doubleNum`/`intNum` do catálogo, não só o `image`.

**Aceite:** URL de host **sem** `Access-Control-Allow-Origin` (o logo do google serve de caso de teste) **renderiza** no editor web; URL inexistente (`https://exemplo.invalido/x.png`) mostra o estado "falhou" com o motivo, distinto do vazio; enquanto carrega aparece o estado de carregando; digitar `0` em Largura não faz a imagem sumir. Comportamento em celular (`driva_demo_app`) inalterado.

### F2 — Catálogo: `image` abrangente (Incremento 4 do item 9) **[depende de F1]** **[sub-agente: especialista-dominio + especialista-infra]**

Hoje: `src`, `width`, `height`, `fit` (`widget_catalog.dart:310-355`). Referência FlutterFlow e o que o `container` já tem.

- **`packages/sdui_core/lib/src/catalog/widget_catalog.dart`**, descriptor do `image`:

| Campo | `FieldKind` | Grupo | Nota |
| --- | --- | --- | --- |
| `src` | `string` (mantém) | content | ganha **`helpText`**: precisa ser URL pública e acessível de outro domínio |
| `width` / `height` | `doubleNum` → **`dimension`** | size | D3; `min: 1` |
| `fit` | `enumeration` (mantém) | content | — |
| `alignment` | `alignment` | content | como a imagem se posiciona na caixa quando `fit` sobra espaço |
| `borderRadius` | `doubleNum` | style | igual ao `container` |
| `backgroundColor` | `color` | style | fundo enquanto carrega e atrás de PNG transparente |
| `semanticLabel` | `string` | content | acessibilidade — obrigação do CLAUDE.md, e hoje o `image` é invisível ao leitor de tela |
| `opacity` | `doubleNum` (0–1) | style | **avaliar**: ignorado no caminho de fallback da D2 |

- **`packages/sdui_flutter/lib/src/builders/image.dart`** — `SduiDimensionBox` para as dimensões, `ClipRRect` para o raio (⚠️ risco R2), `alignment`, `Semantics(label:)`.
- **`apps/driva_editor/lib/.../prop_field/prop_field_shell.dart`** — **renderizar o `helpText`** (hoje morto na UI). Ganho genérico: todo `PropField` do catálogo passa a poder explicar-se, e é aqui que a restrição de URL pública é dita ao usuário em vez de ele descobrir sozinho.

**Aceite:** spec antigo com `"width": 200` (número) continua válido e renderiza igual — **teste explícito**; `"width": "100%"` funciona; raio, alinhamento e cor de fundo aparecem no canvas e no JSON; o `helpText` do `src` aparece no Inspector; nenhuma linha nova no editor foi necessária para os campos novos (a regra do item 9: primitivo novo não exige código no editor).

### F3 — Testes automatizados (por último)

- `sdui_core/test/catalog/widget_catalog_test.dart` — o descriptor novo; **round-trip de compatibilidade**: `{"width": 200}` e `{"width": "100%"}` ambos parseiam.
- `sdui_flutter/test/builders/image_test.dart` (novo) — três estados distintos (vazio ≠ carregando ≠ erro); `width: 0` não colapsa; `fit`/`alignment`/raio aplicados.
- `sdui_flutter/test/renderer_golden_test.dart:55` — golden do `image` regravado (R1).
- `apps/driva_editor/test/.../number_editor_test.dart` — clamp e sinalização de entrada inválida.

## 6. Riscos

| # | Risco | Mitigação |
| --- | --- | --- |
| **R1** | O golden `image` (`renderer_golden_test.dart:55`) renderiza o placeholder de "sem src" e **vai quebrar** ao mudar o visual. | Regravar no mesmo PR, com o diff citado na descrição. |
| **R2** | **`borderRadius` × platform view.** No caminho de fallback da D2 a imagem é um platform view; `ClipRRect` sobre platform view no Flutter Web é limitado e força quebra de camada. Raio arredondado pode não compor. | **Verificar na F2 antes de fechar o campo.** Se não compor: aplicar o raio num `Container` de fundo por baixo e documentar a limitação no `helpText`, ou restringir o raio ao caminho de bytes. |
| **R3** | `fallback` = platform view **não capturável por screenshot** — mata golden de imagem carregada e qualquer "exportar preview como PNG" futuro. | Goldens de `image` sempre com `src` vazio ou fixture local. Registrado em §7. |
| **R4** | Migrar `width`/`height` para `dimension` mexe em spec já salvo. | `DimensionValue.parse` aceita `num`; teste de compatibilidade é critério de aceite da F2. |
| **R5** | `fallback` faz duas tentativas de rede em toda falha (bytes, depois `<img>`). | Aceitável: só ocorre no caminho de erro, e o `<img>` reusa o cache HTTP do navegador. |

## 7. Perguntas para o humano

1. **`WebHtmlElementStrategy.fallback` (D2) está aceito, com o preço da §6 R2/R3?** A alternativa é o proxy no backend — melhor tecnicamente, mais caro e com CISO obrigatório (SSRF).
2. **A F1 sai como `bugfix/*` avulso, antes do item 24?** É um arquivo de builder mais um editor do inspector. Recomendo **sim**.
3. **A F2 entra como "Incremento 4" do item 9, sem número novo no roadmap?** É o precedente do `textField` (roadmap linha 67).
4. **`opacity` entra?** É ignorado no caminho de fallback — uma prop que às vezes não faz nada é pior que prop nenhuma. Inclinação: **fora**.
5. **Numeração:** ver o aviso do topo.

## 8. Evoluções deixadas de fora (registro)

- **Proxy de mídia no backend** com allow-list — resolveria CORS sem platform view; exige CISO.
- **`SduiAuthoringScope`** — separar chrome de autoria (placeholders, quadrado cinza) do que o app do cliente desenha (D4). Hoje um `image` sem `src` publicado desenha um quadrado cinza em produção.
- **`isRequired` que valida de verdade** — hoje é só um asterisco (`prop_field_shell.dart:56-57`); campo obrigatório vazio não gera `errorText` nem diagnóstico. Candidato natural: uma regra nova em `diagnoseTree`, que já é o lugar de "problema do documento".
- **Upload de imagem pelo editor** — item 27 (storage).
- **Placeholder/blurhash por imagem**, `Image.memory`/base64, `svg`, `avatar`/`aspectRatio` (já na fila do item 9, `plans/09-catalogo-widgets/plan.md:44,52`).

## 9. Definition of Done

- `flutter analyze` verde; `flutter test -r compact` do `sdui_flutter`, `sdui_core` e `driva_editor` passando (golden regravado).
- E2E manual em **homologação** (não localhost — lição do 9g), roteiro mínimo: colar a URL do logo do google (host sem ACAO) → **a imagem aparece**; colar `https://exemplo.invalido/x.png` → estado "falhou" com o motivo; apagar a URL → estado vazio, visualmente distinto dos outros dois; `width: 100%` estica; `width: 0` não some; raio e alinhamento visíveis; recarregar a página e conferir que o spec reabre igual.
- `docs/NN-<nome>/` (final_report + CHANGELOG `Unreleased`); `docs/roadmap.md` e `docs/plans/README.md` atualizados **pelo tech-manager**.
