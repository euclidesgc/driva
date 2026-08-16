# Rodada 00 — o "antes", registrado por causa e não por foto

> **Não há fotos nesta pasta, e não haverá — ver D33 do `plan.md`.** As três chegaram por
> mensagem e, quando foram salvas, a F1 e a F1b já estavam mergeadas e no ar: o estado que
> elas mostram não é mais reproduzível em homologação.
>
> **O que este README documenta é o "antes".** Cada sintoma tem a causa no código, com
> arquivo e linha — evidência que não envelhece com o build, ao contrário da foto. Os
> aceites 28 e 35-A perderam a cláusula de pareamento e apontam para a `rodada_01`.
>
> **A regra que fica:** evidência de campo é arquivada **no dia em que chega**, antes de
> qualquer PR que a torne irreproduzível. Foto em aplicativo de mensagens não é evidência
> arquivada.

## A lista de conteúdos — tema escuro

Foto enviada pelo dev humano em 2026-08-16, de um Android em modo escuro acessando
`hml.driva.duckdns.org` — a **tela de conteúdos do projeto** (`contents_module`), não o
editor. É a evidência que reordenou o item 41 e partiu a F1 em duas (§8 do `plan.md`).

**O que a foto mostra, e por que cada coisa importa:**

| Sintoma | Causa (confirmada no código) |
| --- | --- |
| Painel **CATEGORIAS** ocupando ~70% da largura | `SizedBox(width: 272)` hardcoded numa `Row` crua (`project_detail_page.dart:113`), sem `LayoutBuilder`. A 412 px isso é 66% da tela. **O `ResizableSplitView` não está envolvido** — ele tem um único uso, no `editor_workspace.dart`. |
| Título **"Todos os conteúdos" descendo uma letra por linha** | `Expanded` resolvendo para largura **zero** (`content_panel_view.dart:140`): na mesma `Row`, busca (`width: 220`), sort e toggle são fixos e medidos primeiro; a sobra é negativa. Um `Text` com `maxWidth: 0` quebra por grafema. |
| Busca cortada em `Busc…` | Mesma `Row`, mesma causa. |
| AppBar de duas faixas + breadcrumb consumindo altura | Chrome do `AppShell` (item 16c) sem comportamento por faixa. |

**As duas primeiras causas têm de ser corrigidas na mesma fase.** Corrigir só as
categorias não resolve: mesmo com elas fora do caminho, o painel a 412 px tem 364, e
`220 + sort + toggle` continua estourando.

---

## O editor — o canvas ausente

Segunda foto do dev humano (2026-08-16), do **editor** no mesmo aparelho — não da
lista. É um defeito **diferente** do anterior, e mais grave.

**O canvas desaparece por completo.** O painel de Widgets ocupa ~75% da largura e o
Inspector fica espremido à direita com todos os rótulos truncados (`Págin…`,
`Usar área se…`, `Respeitar o…`, `Respeitar a…`). O mock do dispositivo — o centro
inteiro do trabalho no editor — **não aparece em lugar nenhum**.

Não é "apertado": é o editor sem a peça que justifica ele existir.

**A decisão do humano sobre isto (2026-08-16):** o editor **não** vira mobile — arrastar
widget em 412 px é outro produto. Mas ele **degrada com dignidade**: abaixo do limiar
`compact`, mostra uma tela explicando que o construtor pede janela maior, com dois
caminhos — **"Ver conteúdo"** (a rota `/preview` da F2, que já está no ar) e **"Voltar aos
conteúdos"**.

O que transforma o beco em caminho é a F2 ter chegado antes: sem ela, o aviso seria só
um "não dá". Com ela, o celular tem o que fazer.

---

## A lista de conteúdos — tema claro

Terceira foto do dev humano (2026-08-16): a **mesma tela de conteúdos** da primeira, no
mesmo aparelho, em **tema claro**. Repetia os três sintomas — CATEGORIAS ocupando a maior
parte da largura, título quebrando por grafema, busca cortada.

Ela existia para fechar uma hipótese antes que alguém a perseguisse: **as causas são de
layout, não de tema.** E isso continua provado sem a foto — as três causas da tabela acima
são `SizedBox` e `Expanded`, nenhuma delas lê cor. Nenhuma correção deste item mexe em
`EditorColors` nem nas paletas.

---

## Onde está o "depois"

`../rodada_01/` — três fotos do mesmo aparelho, com as F1, F1b, F2 e F4 no ar. O README de
lá diz qual aceite cada uma atende.
