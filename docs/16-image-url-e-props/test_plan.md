# Test plan — item 39 (URL da imagem e props)

Mapa do que foi automatizado, do que ficou para o olho humano e do **rastro a limpar no wrap**.
Régua: `plan.md` §2 (matriz A/B/C/D), §10 (roteiro) e §11 (DoD).

## Rastro desta fase — o que existe e como sai

| O que | Onde | Como se remove |
| --- | --- | --- |
| `e2e_hml.sh` — contrato por API | `docs/16-image-url-e-props/` | arquivo de doc; fica como evidência viva (padrão dos itens 9g e 38) |
| `e2e_shots.sh` + `e2e_drive.mjs` — prints headless | `docs/16-image-url-e-props/` | idem |
| Conteúdo de teste no hml (slug `e2e-39-contrato` / `e2e-39-canvas`) | projeto `default` do hml | **os próprios scripts purgam** no começo e no fim |
| Categoria `E2E 39` | projeto `default` do hml | só é criada se o projeto não tiver nenhuma; apagada no fim |
| Chrome headless + `--user-data-dir` temporário | processo local | `trap EXIT` do `e2e_shots.sh` |

**Instrumentação de código: nenhuma.** A stack real existe (backend + proxy no ar em hml), então
nada de `log('[e2e]')`, nada de fake no DI. **Zero linha de código-fonte tocada** — não há o que
limpar no wrap além dos artefatos acima, que são documentação.

## O que a máquina prova

### `e2e_hml.sh` — 49 asserções, verde

Roda contra `https://api-hml.driva.duckdns.org/v1`. **Não refaz a matriz de segurança da §11.4**
(27–44): ela já roda como suíte `e2e` do Nest, no CI, contra servidor efêmero. O que este script
mede é o que aquela suíte não pode medir — o **ambiente**:

| Seção | Cobre |
| --- | --- |
| 0 | Cancelas estáticas do DoD: 5 (`Color(0x…)` fora de `theme/`), 5b (`loadingBuilder`), 5c (`showDiagnostics`), 5d (`gates_guard.sh`), 6 (nenhum condicional sobre o tipo `image` no editor) e a D11 (a URL do proxy não existe dentro de `packages/`) |
| 1 | hml no ar **e servindo o artefato das F1–F4** (as strings dos três estados e do proxy estão no bundle publicado) |
| 2 | **Caso A** via proxy: 200, content-type de imagem, `ACAO` = origem do editor (não `*`), ETag, `Cache-Control`, `nosniff` |
| 3 | **Caso B**: guarda de que o host ainda **não** serve ACAO (senão virou caso A e o teste é inválido) + 200 via proxy + ACAO + revalidação `If-None-Match` → 304 |
| 4 | **Caso C**: 502, corpo genérico (erro sem oráculo), ACAO presente **também no erro** |
| 5 | Bordas: `url` ausente/vazia → 400; alvo HTML → 400; `/v1/public/media/proxy` **não existe** (D11) |
| 6 | Spec: compat `width: 200` numérico (DoD 25), `width: "100%"` + props novas da F4, round-trip byte a byte, `image` sem `src` é spec válido |

### `e2e_shots.sh` + `e2e_drive.mjs` — 29 asserções, 26 verdes

Dirige a tela do hml por CDP puro e assere cada estado por **rede** e por **spec**:

| Estado / caso | Asserção de máquina | Print |
| --- | --- | --- |
| Vazio (DoD 21) | zero requisições de imagem | `20_estado_vazio.png` |
| Carregando (DoD 22) | com rede a 12 KB/s e cache desligado, o download **não terminou** no instante da captura (`loadingFinished` ausente) | `22_estado_carregando.png` |
| Carregado / caso A (DoD 18) | proxy 200 + content-type de imagem | `18_estado_carregado.png` |
| Falhou / caso C (DoD 20) | proxy 502 | `20b_estado_falhou.png`, `20c_tooltip_do_erro.png` |
| **Os quatro lado a lado (DoD 24)** | os 6 pares de recortes são **bytes diferentes** | `24_quatro_estados_lado_a_lado.png` |
| Caso B (DoD 19) | requisição ao proxy com a URL do relato + 200 + **zero** chamadas diretas ao host | `19_caso_b_carregado.png` |
| Backend real, não fake (DoD 13b) | ≥ 4 requisições de imagem, todas ao proxy | `13b_rede_via_proxy.png`, `rede_imagens.json` |
| `helpText` nos dois caminhos (D8) | — (visual) | `12_inspector_helptext.png` |
| Props da F4 | `width: "100%"`, `borderRadius`, `alignment` sobrevivem ao round-trip | `11a_props_f4.png` |
| Compat (DoD 25) | `width: 240` numérico intacto no spec, imagem carrega | `25_compat_width_numerico.png` |
| Reload (§10.14) | spec idêntico após recarregar o navegador | `14_reabre_apos_reload.png` |
| `width: 0` (D6) | o clamp agiu: `0` vira `1` no spec | `23a_largura_zero.png` |

## Achados

### A-39-01 — **`Largura`/`Altura` do `image` perderam o sinal da D15** (3 asserções vermelhas)

**O que o plano exige** (D15, DoD 23): `0` mostra `helperText` "Ajustado para o mínimo (1)";
`abc` mostra `errorText`; **os dois sinais se distinguem**.

**O que a rodada mediu:** nenhuma das duas mensagens aparece. O campo mantém o texto digitado
(`0`, `abc`) enquanto o spec grava `1`, sem sinal nenhum — e os prints de `0` e de `abc` são a
mesma tela.

**Causa:** a mensagem existe em `NumberEditor`
(`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/number_editor.dart:68,132-133`),
mas a F4/D3 migrou `image.width`/`height` de `FieldKind.doubleNum` para `FieldKind.dimension` —
e `DimensionEditor` (`.../prop_field/dimension_editor.dart:73-74`) clampa **sem** `helperText` e
descarta texto inválido **sem** `errorText`. O sinal que a F1 entregou foi perdido pela F4,
dentro do mesmo item.

**Decisão é do humano:** bloqueia o item 39 ou vira item próprio.

**Resolvido** pelo bugfix `dimension-editor-sinaliza-ajuste` (virou item próprio). `DimensionEditor`
passou a sinalizar `helperText` e `errorText` nas duas unidades. A rede automática **não** veio
junto — é a F5, e os quatro mutantes que ficaram vivos estão listados abaixo.

### A-39-02 — os rótulos de acessibilidade dos três estados não chegam ao canvas do editor (severidade baixa)

`ImageEmptyBox`/`ImageLoadingBox`/`ImageErrorBox` declaram `Semantics(label:)`, mas dentro do
editor o `SelectableNode`
(`.../widgets/canvas/selectable_node.dart:54`) envolve cada nó num `Semantics(label: <tipo>)`
com gesto e o engine funde os descendentes: nenhum dos três rótulos aparece na árvore
acessível do canvas. **Não é item do DoD** (a F4 aceite 6 é teste de widget sobre o renderer,
não sobre o editor) e **não afeta o app publicado**. Fica registrado porque foi o que obrigou as
asserções deste E2E a serem de rede e de pixel, não de semântica.

### A-39-03 — DoD item 49 não tem objeto (severidade baixa)

O item 49 pede as "variáveis novas do proxy (teto, timeout, rate limit) documentadas em
`docs/deploy/coolify.md` e configuradas no painel". Elas **não são variáveis de ambiente**: são
constantes de compilação em `backend/src/media/media.constants.ts`. Ou o item se fecha como
"não se aplica", ou as constantes viram env — decisão do humano no fechamento.

### A-39-04 — `Infinity`/`NaN` digitados entram no spec e quebram o round-trip (severidade média, **pré-existente**)

Achado na re-revisão do bugfix `dimension-editor-sinaliza-ajuste`. **Não é regressão dele** — o
caminho já existia antes, nos dois editores. Fica aqui porque é a **mesma família** do bloqueador
que originou o bugfix: valor que entra no spec e não volta.

`NumberTextField` não tem `inputFormatters`, e `keyboardType` não restringe caractere em
web/desktop. `double.tryParse` aceita `"Infinity"`, `"-Infinity"` e `"NaN"` — medido rodando o
código:

| Digitado | Unidade | O que acontece |
| --- | --- | --- |
| `Infinity` | percentual | **exceção** `UnsupportedError` dentro de `PercentDimension.toJson()` (`rounded.toInt()` sobre infinito) |
| `NaN` | percentual | grava `"NaN%"` no spec; `DimensionValue.parse` devolve `null` — **o valor some no reload**, e o `helperText` mente ("Ajustado para o máximo (NaN)") |
| `NaN` / `Infinity` | pixels | grava `double` não-serializável; `jsonEncode` lança na hora de salvar |

`-Infinity` em percentual é o único caso são: o piso `0` o captura e vira `0%`.

O conserto é uma linha — rejeitar não-finito como entrada inválida (`errorText`), no mesmo ponto
em que hoje se rejeita texto não numérico. **Vale para `DimensionEditor` e `NumberEditor`.**
Triagem é do tech-lead: entra como bugfix próprio ou vira caso da F5.

## Casos obrigatórios da F5 — a bateria automatizada

Levantados por **mutação**: cada linha abaixo foi introduzida no código, a suíte do
`driva_editor` rodou inteira e **passou verde (270/270)**. São buracos confirmados, não
suposições. A F5 só fecha quando cada mutante abaixo ficar vermelho.

| # | Mutação que sobrevive | Alvo | O que o teste tem de afirmar |
| --- | --- | --- | --- |
| M1 | apagar `if (clamped == raw) return null;` de `clampMessageFor` | `.../prop_field/numeric_clamp.dart` | valor **dentro** da faixa não produz `helperText` nenhum — nem em `NumberEditor`, nem em `DimensionEditor`, nas duas unidades |
| M2 | trocar o piso do ramo percentual por `min: widget.field.min, max: widget.field.max` | `.../prop_field/dimension_editor.dart` | em `image` (`min: 1`), `1` em **percentual** grava `"1%"` — nunca é clampado contra o `min` de pixels; e `150` percentual passa intacto, sem `helperText` (não existe teto em percentual) |
| M3 | apagar o piso: `_clampedPercent(num raw) => raw` | `.../prop_field/dimension_editor.dart` | `-50` em percentual grava `"0%"` **e** mostra "Ajustado para o mínimo (0)"; o resultado reparseia por `DimensionValue.parse` |
| M4 | remover o `?? 0` de `_clampedPixels` | `.../prop_field/dimension_editor.dart` | campo `dimension` **sem `min` declarado** não aceita negativo (hoje os 10 do catálogo declaram `min`, então o mutante é silencioso por construção — o teste precisa de um `PropField` sintético) |

**M3 é a régua da D15.** Foi o bloqueador da rodada 1 deste bugfix: `"-50%"` entrava no spec, a
regex do kernel (`^(\d+(?:[.,]\d+)?)\s*%$`) não reparseava, e o valor sumia no reload — a D15
violada pelo PR que existe para cumpri-la. O ramo pixel já tinha essa rede; o percentual não
tem nenhuma.

**Régua de aceite dos quatro:** o teste não pode se contentar com "o spec ficou certo". Tem de
afirmar as **duas metades** da D15 juntas — o valor que fica no spec **e** o sinal na tela
(`helperText` presente/ausente, distinto do `errorText`). M1 sobrevive justamente porque nenhum
teste hoje afirma a **ausência** da mensagem.

## O que fica para o olho humano

Em [`roteiro_e2e_humano.md`](roteiro_e2e_humano.md). Resumo do que **não** dá para automatizar:

| # | O que | Por quê |
| --- | --- | --- |
| H1 | Os quatro estados serem **legíveis como significado** (DoD 24) | a máquina prova que os pixels diferem; que a diferença *comunica* é julgamento |
| H2 | O motivo do erro ser **compreensível** sem DevTools | idem |
| H3 | **`driva_demo_app` no celular** (DoD 26): imagem direto do host, sem proxy | exige aparelho/emulador e o app móvel; fora do alcance de um Chrome headless |
| H4 | **Ctrl+S** funcionar com teclado real, inclusive com o cursor num campo | teclado sintético via CDP não passa pelo mesmo caminho — medido nesta rodada: o `Ctrl+S` sintético é intermitente, e por isso o driver salva pelo **botão** |
| H5 | Contraste e legibilidade das três caixas de estado em monitor real | percepção |
