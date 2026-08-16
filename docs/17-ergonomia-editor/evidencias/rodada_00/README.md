# Rodada 00 — evidência de campo (o "antes")

> **Esta pasta guarda o estado ANTES da F1.** Sem ela, os aceites 1 e 28 do DoD não
> têm contra o que ser comparados — um print "depois" sozinho não prova melhora.

## `00_evidencia_campo_android.jpg` — **pendente de arquivamento pelo dev humano**

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

## Como arquivar

Salve a foto original neste diretório com o nome `00_evidencia_campo_android.jpg`.
**Antes de a F1 mergear** — é o item 25 do DoD.

---

## `01_evidencia_campo_editor_android.jpg` — **pendente de arquivamento**

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

## Uma nota sobre o tema

A foto `00` é do tema escuro; a `01` e a terceira (mesma tela de conteúdos em tema claro)
mostram que **o defeito não é do tema**. As causas são de layout, não de cor.
