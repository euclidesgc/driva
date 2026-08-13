# plan.md — Item 8b: Legibilidade avançada do painel JSON

> Documento de planejamento. Dono na execução: **especialista-apresentacao**. Base: `docs/roadmap.md` › Marco 1.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. 0-dep, não toca backend nem kernel.
> **Prioridade declarada: baixa.** Este plano existe para que o item possa ser executado sem redescoberta — não para defender que ele seja feito agora.

## 1. Objetivo e recorte

Os itens 7 e 8 entregaram o painel de JSON: preview em tempo real, somente-leitura, copiável, com syntax highlight próprio (sem dependência) e números de linha. Falta o que separa "dá para ler" de "dá para navegar" num spec de 300 linhas:

1. **Dobrar seções** (colapsar um objeto/array pelo triângulo na sarjeta).
2. **Casar `{`/`}`** — destacar o par correspondente quando o cursor está perto de um delimitador.
3. **Destacar a chave-pai** do bloco onde o cursor está (a "trilha" de contexto).

**Fica fora:** edição do JSON no painel (é somente-leitura por decisão de produto — o editor visual é a fonte da verdade), busca dentro do JSON, e "ir para o nó" clicando no JSON (registrado em §6 como a evolução mais valiosa).

## 2. O obstáculo real (e por que este item é maior do que parece)

O painel hoje é assim (`json_view.dart`):
```
SelectableText.rich( TextSpan(children: JsonHighlighter.highlight(json, ...)) )
```
`JsonHighlighter` é um **varredor de caracteres** sobre a saída de `JsonEncoder.withIndent` (112 linhas, sem parser): distingue chave de valor olhando o próximo caractere não-branco. Isso é perfeito para colorir e **insuficiente para as três funcionalidades pedidas**, que exigem saber **estrutura**: onde um bloco começa e termina, quem é o pai de quem, qual linha corresponde a qual nó.

Além disso, `SelectableText.rich` não expõe posição de cursor de forma utilizável para "destacar o par próximo ao cursor".

**Conclusão honesta:** as três funcionalidades exigem trocar a representação de "uma string colorida" para "uma lista de linhas com metadados estruturais". É uma reescrita do painel, não um acréscimo. O plano abaixo faz essa troca de forma incremental e mantém o highlighter atual como está.

## 3. Decisões

**D1 — Um modelo de linha, derivado do spec e não do texto.**
Em vez de formatar `ContentSpec.toJson()` para string e depois tentar entender a string, **gerar as linhas diretamente** a partir do mapa, com a estrutura conhecida no caminho:
```dart
class JsonLine {
  final int indent;
  final String text;          // já formatado, sem quebra
  final int depth;
  final String? nodePath;     // "root.children.0" — a trilha
  final int? closesLine;      // se abre bloco, a linha que o fecha
  final bool isBlockStart;
}
```
Um gerador puro (`JsonLineBuilder`) percorre `Map`/`List` e emite as linhas. Ganhos: dobrar vira "esconder o intervalo `[i+1, closesLine-1]`"; casar chaves vira uma consulta a `closesLine`; a trilha sai de graça.
> **Efeito colateral valioso:** com `nodePath` por linha, a evolução "clicar no JSON seleciona o nó no canvas" (§6) passa a custar quase nada — e essa é, provavelmente, a funcionalidade que o usuário realmente quer.

**D2 — Reaproveitar o `JsonHighlighter` sem tocá-lo.**
Ele passa a colorir **uma linha por vez** (a assinatura já aceita qualquer string). Zero risco de regressão no que já funciona, e o `json_highlighter_test.dart` existente continua válido.

**D3 — `SelectableText.rich` por linha, dentro de um `ListView.builder`.**
Troca o texto único por uma lista virtualizada. Ganho colateral: spec grande deixa de renderizar tudo de uma vez. Custo: **a seleção de texto deixa de atravessar linhas** — copiar arrastando por 10 linhas para de funcionar.
> **Mitigação obrigatória:** o botão "Copiar" da `JsonToolbar` (que já existe) passa a ser o caminho oficial, e ganha "copiar seção" quando um bloco está selecionado. **Sem isso, este item piora o painel em vez de melhorar** — é o risco número um aqui.
> Alternativa a avaliar na fase: manter `SelectableText.rich` único e implementar só a dobra (reconstruindo a string sem as partes dobradas). Perde a virtualização, mantém a seleção contínua. **Decidir com o humano (§7) — a troca é de UX, não técnica.**

**D4 — A dobra é estado local do painel.**
Um `Set<int>` de linhas dobradas no `State` do painel. **Nunca** no `EditorCubit`: dobrar uma seção não é mudança de documento e não pode reconstruir canvas, árvore ou inspector (regra de rebuild mínimo, item 3b). Não persiste entre aberturas.

## 4. Fases

### F1 — O gerador de linhas (puro, testável)
- **`core/util/json_line.dart`** e **`core/util/json_line_builder.dart`** (ou `core/widgets/painters/`, junto do highlighter — **decidir**: o highlighter mora em `painters/`, mas isto não pinta nada; `core/util/` é mais honesto).
- `List<JsonLine> buildJsonLines(Map<String, dynamic> json)` — puro, sem Flutter, 100% testável.
- **Aceite:** para o fixture `content_valid.json`, o texto concatenado das linhas é **byte a byte igual** ao `JsonEncoder.withIndent('  ').convert(...)` atual. Esse é o teste que garante que nada visual mudou.

### F2 — O painel virtualizado + dobra
- **`.../json_preview/json_line_row.dart`** (novo) — uma linha: sarjeta com número, triângulo de dobra quando `isBlockStart`, e o texto colorido.
- **`.../json_preview/json_view.dart`** — vira `StatefulWidget` com o `Set<int>` de dobradas e um `ListView.builder` sobre as linhas **visíveis**.
- **`.../json_preview/line_gutter.dart`** — o número de linha migra para dentro do `JsonLineRow` (a sarjeta separada deixa de fazer sentido com virtualização, porque o alinhamento 1:1 passa a ser por linha). **Arquivo provavelmente deletado** — confirmar.
- **`.../json_preview/json_toolbar.dart`** — botões "Expandir tudo"/"Recolher tudo" + o "copiar seção" da D3.

### F3 — Casar delimitadores e trilha da chave-pai
- Com `closesLine` no modelo, destacar o par é pintar o fundo das duas linhas quando uma delas está sob o ponteiro/foco.
- A trilha (`nodePath` da linha do topo visível) aparece numa faixa fina acima do painel — o mesmo padrão do breadcrumb do item 16c, mas local.
- **Tokens novos em `core/theme/syntax_colors.dart`**: fundo do par casado e fundo da linha ativa, **com variante dark** (Gate 4 — "tokenizar tudo, sem exceção").

### F4 — Testes
`json_line_builder_test.dart` (a igualdade byte a byte da F1, blocos aninhados, arrays vazios), widget test da dobra (dobrar esconde o intervalo certo; expandir tudo volta), e **manter** o `json_preview_panel_test.dart` e o `json_highlighter_test.dart` existentes passando **sem alteração** — se precisarem mudar, a compatibilidade quebrou.

## 5. Mapa de paralelismo

```
F1 ──► F2 ──► F3 ──► F4
```
Serial. O item inteiro é pequeno-médio, mas **a F2 carrega o risco da D3** — não começar sem a decisão do §7.

## 6. Impacto nos outros planos (revisão cruzada)

- **Item 29 (dados)** — o painel passará a mostrar `params`/`dataSources`/`previewValue`. O gerador da F1 não se importa (percorre o mapa genérico). **Nenhum trabalho extra** — bom sinal do desenho.
- **Item 21 (componentes)** — o rascunho mostra nós `component`, a versão publicada mostra a árvore expandida. Se um dia o painel oferecer "ver JSON publicado", a diferença vai chamar atenção — **é desejável** e não exige nada aqui.
- **Item 3b (rebuilds)** — a D4 preserva a disciplina conquistada lá. Dobrar não pode passar pelo cubit.
- **Nenhuma contradição** com os itens 7 e 8: o highlighter é preservado inteiro (D2).

## 7. Perguntas para o humano (bloqueiam a F2)

1. **Vale perder a seleção contínua de texto (D3)?** É a troca central. Se a resposta for não, a implementação muda: só dobra, sem virtualização, mantendo o `SelectableText.rich` único.
2. **A funcionalidade que você realmente quer não seria "clicar no JSON e selecionar o nó no canvas"?** Ela cai de graça com o modelo da D1, e provavelmente vale mais do que as três listadas. **Se sim, este item deveria ser reescrito no roadmap com esse objetivo** — o plano já a deixa a um passo.
3. **Prioridade:** manter em baixa? O roadmap diz que sim.
