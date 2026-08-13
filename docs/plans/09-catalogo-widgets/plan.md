# plan.md — Item 9: Catálogo de widgets (track contínuo)

> Documento de planejamento. Dono na execução: **tech-lead** (rotativo por incremento). Base: `docs/roadmap.md` › Marco 2.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend** — o spec é JSONB opaco.
> **Este plano é diferente dos outros:** o item 9 não termina. Ele é um **processo repetível** mais uma **fila priorizada**. O que segue é o roteiro de um incremento (que se repete) e a lista do que vem por aí.

## 1. Estado atual (2026-08-13)

**24 primitivos** no catálogo, todos com descriptor + builder + entrada no registry:
`container, column, row, stack, text, image, icon, button, textField, switch, checkbox, card, divider, sizedBox, padding, center, spacer, wrap, expanded, listView, gridView, radio, dropdown, slider`

Distribuídos em 4 categorias (`WidgetCategories`): Básicos, Layout, Formulário, Listas.

Os editores de propriedade já cobrem 10 `FieldKind` (string, doubleNum, intNum, dimension, boolean, color, enumeration, edgeInsets, alignment, iconName) com estados múltiplos e binding — entregues no item 9b. **A infraestrutura está madura; o que falta é população.**

## 2. O processo repetível — "como adicionar um primitivo"

Sete passos. **Um primitivo novo não deve exigir nenhuma linha de código no editor** — se exigir, algo saiu do lugar e é isso que precisa ser corrigido primeiro.

1. **Descriptor** em `packages/sdui_core/lib/src/catalog/widget_catalog.dart`: `WidgetDescriptor(type, label, iconName, category, slot, fields: [...])`.
   - `slot`: `none` (folha) / `single` (um filho) / `multi` (lista).
   - Cada `PropField` com `key`, `kind`, `label`, `group` (`FieldGroups`), e **`defaultValue` quando houver** — é ele que alimenta `defaultProperties()` e, portanto, o nó criado ao arrastar (`defaultNode`, linha 1105).
   - `isBindable: false` só quando bindar não faz sentido.
2. **Builder** em `packages/sdui_flutter/lib/src/builders/<nome>.dart`: `Widget build<Nome>(BuildContext context, SduiNode node, SduiRenderer r)`.
   - Ler props com os helpers de `src/parsing/parsers.dart`; **nunca** `node.properties['x'] as String` cru.
   - Filhos: `r.renderAll` / `r.maybeRender` / **`r.renderFlexChildren`** (só em `row`/`column` — é o que autoriza `Expanded`).
   - Exceção de gate registrada: builders **não** caem no Gate 1 (registry/plugin).
3. **Registro** em `packages/sdui_flutter/lib/src/builders/default_registry.dart` (uma linha no mapa + um import).
4. **Eventos** (depois do item 28): declarar `events` no descriptor se o primitivo tiver gesto.
5. **Fixture**: acrescentar o primitivo a `packages/sdui_core/test/fixtures/content_valid.json`, que é o spec de referência do kernel.
6. **Diagnóstico**: se o primitivo só faz sentido dentro de um pai específico (como `expanded`/`spacer` em flex), acrescentar a regra em `diagnostics/diagnose_ops.dart` — senão o usuário monta algo que o renderer ignora, sem aviso.
7. **Teste**: caso no `widget_catalog_test.dart` (contrato descriptor↔registry) + golden do builder quando o visual for a razão de existir.

**Verificação de contrato que já existe:** o `widget_catalog_test.dart` cobra a correspondência entre catálogo e registry (comentário no `default_registry.dart:29` confirma). Ou seja, **esquecer o passo 3 quebra o teste** — a rede de segurança está armada.

## 3. Fila priorizada (o que falta, e por quê nessa ordem)

Critério de ordenação: (a) o que o FlutterFlow tem e é usado em quase toda tela; (b) o que não depende de mecanismo ausente; (c) o que destrava casos de uso reais do produto.

### Leva A — completar o básico visual _(nenhuma dependência)_
| Primitivo | Por quê | Notas |
| --- | --- | --- |
| `richText` / `text` com spans | Texto misto (negrito no meio da frase) é pedido em toda landing | Pode ser um `FieldKind` novo ou lista de spans — **decidir** |
| `avatar` | Presente em quase todo cabeçalho | `CircleAvatar`, props: imagem/iniciais/tamanho |
| `chip` / `badge` | Selo de status, tag | Folha, barato |
| `progressIndicator` | Linear e circular | Enum de variante |
| `banner`/`alert` | Mensagem com tom (info/sucesso/erro) | Reusa o enum de tom do item 28 (`showMessage`) |

### Leva B — layout que hoje falta _(nenhuma dependência)_
| Primitivo | Por quê |
| --- | --- |
| `aspectRatio` | Imagem responsiva sem esticar |
| `positioned` | `stack` existe mas não há como posicionar dentro dele — **buraco real do catálogo atual** |
| `align` | Hoje só há `center` |
| `singleChildScrollView` | Conteúdo maior que a tela sem virar lista |
| `opacity` / `visibility` | Esconder condicionalmente (ganha sentido pleno com o item 29) |

### Leva C — dependentes de mecanismo _(não fazer antes)_
| Primitivo | Depende de |
| --- | --- |
| `tabBar` / `tabView` | Estado local de runtime (item 29, F7) |
| `form` + validação | Idem |
| `datePicker` / `timePicker` | Idem + eventos de valor |
| `listView` com template por item | **Item 29, F6** — já planejado lá |
| `imagePicker` / upload | Storage (item 27) + ação de escrita |
| `webView`, `map`, `video` | Dependências externas do app cliente; exigem contrato de plugin no `driva_client` |

### Leva D — melhorias nos existentes
- `button`: variantes (filled/outlined/text/icon), estado de carregando, ícone à esquerda/direita.
- `image`: `fit`, `placeholder`, `errorWidget`, borda arredondada.
- `container`: gradiente, sombra, borda por lado.
- `text`: `maxLines`, `overflow`, `letterSpacing`.

## 4. Anatomia de um incremento (é assim que cada PR fica)

**Um incremento = 3 a 5 primitivos da mesma leva, ou uma leva de melhorias.** Não misturar levas: o PR fica revisável e o E2E é focado.

Fases dentro do incremento — e o paralelismo:
```
F1 descriptors (sdui_core)  ──┐
F2 builders (sdui_flutter)  ──┼─► F4 fixture + testes
F3 diagnósticos (se houver) ──┘
```
- **F1 e F2 podem ser feitos por pessoas diferentes** desde que os `type` e as `key` de prop estejam congelados na abertura do incremento (é literalmente o contrato entre as duas).
- **Não** paralelizar dois incrementos diferentes: os dois tocam `widget_catalog.dart` e `default_registry.dart`, e o conflito de merge é garantido.

## 5. Regras que não podem ser violadas (as que já custaram caro)

1. **Nada hardcoded no editor.** Paleta, Inspector e defaults derivam do catálogo. Um `if (node.type == 'x')` na presentation é um bug de arquitetura, não um atalho.
2. **`defaultValue` no descriptor é o mesmo que o builder aplica na ausência da prop.** Se divergirem, o canvas mostra uma coisa e o app mostra outra — o pior bug possível num produto de SDUI. O `PropField.defaultValue` já documenta isso ("O renderer aplica este mesmo default na ausência da prop").
3. **`FieldKind` novo é decisão de arquitetura, não de widget.** Antes de criar um, verificar se os 10 existentes não cobrem. Cada `FieldKind` novo custa um editor novo no Inspector, um resumo no `PropGroupSummary` e um caminho no parser.
4. **Primitivo sem builder não entra no catálogo** (o `_UnknownTypeBox` do renderer existe para spec de versão futura, não para descuido).
5. **Categoria nova exige mexer em `WidgetCategories.inPaletteOrder`** — senão o grupo não aparece na paleta.

## 6. Impacto nos outros planos (revisão cruzada)

- **Item 28 (eventos)** — passo 4 do processo (§2) **é** a obrigação que nasce lá: todo primitivo com gesto declara `events`. Sem isso, widget novo nasce inerte em silêncio.
- **Item 29 (dados)** — a Leva C inteira depende dele. Tentar `tabBar` antes é retrabalho garantido.
- **Item 22 (componentes)** — a F3 de lá propõe extrair um `palette_shell` comum entre a paleta de widgets e a vitrine de componentes. Se isso acontecer, **este processo não muda** (a paleta continua derivando do catálogo), mas o arquivo a tocar em caso de mudança visual passa a ser o shell.
- **Item 30 (breakpoints)** — se props ganharem variação por breakpoint, **todo `PropField` passa a poder ter override**. O plano 30 precisa decidir se isso vale para todos ou só para um subconjunto (tamanho/espaçamento) — e este processo herda a decisão no passo 1.
- **Item 24 (publicação)** — primitivo novo **não** invalida spec publicado (specs antigos não usam o tipo novo). O caminho perigoso é o inverso: **remover** ou renomear um primitivo quebra spec publicado. **Regra: tipo do catálogo nunca é renomeado nem removido sem migração de spec.** Registrar isso como invariante do produto.

## 7. Definition of Done (por incremento)

- [ ] `flutter analyze` verde; `dart test`/`flutter test` verdes.
- [ ] `widget_catalog_test.dart` cobrindo os tipos novos (contrato catálogo↔registry).
- [ ] Fixture atualizado e parseando.
- [ ] Golden do builder quando o visual justificar.
- [ ] E2E manual: arrastar cada primitivo novo da paleta, editar cada prop no Inspector, ver refletir no canvas.
- [ ] `CHANGELOG.md` › `Unreleased` listando os primitivos.
- [ ] `docs/roadmap.md`: sublista do item 9 com o incremento entregue.

## 8. Perguntas para o humano

1. **Qual leva primeiro?** Recomendo **B antes de A**: `positioned` é um buraco real (temos `stack` sem como posicionar), e `align`/`aspectRatio` desbloqueiam layouts que hoje são impossíveis.
2. **`richText` vale a complexidade** de um `FieldKind` novo, ou resolvemos com `text` + `row`?
3. **Quantos primitivos por incremento?** Assumido 3–5.
