# Rodada 01 — o "depois" da F1 e da F1b

> Três fotos de aparelho Android, tema claro, 2026-08-16 às 11:45, contra
> `hml.driva.duckdns.org` — com as F1, F1b, F2 e F4 no ar.

## `01_conteudos_android.jpg` — atende o **aceite 28** (e o 29, e o 31)

A tela de conteúdos do projeto "Megazord - App RE". É o par funcional da causa registrada em
`rodada_00/README.md`:

| O que a tabela da `rodada_00` previa | O que a foto mostra |
| --- | --- |
| painel CATEGORIAS ocupando ~70% da largura | **não há barra lateral** — virou o botão `☰` ao lado do título (aceite 29) |
| "Todos os conteúdos" descendo uma letra por linha | **uma linha horizontal**, com "1 conteúdo" abaixo (aceite 28) |
| busca cortada em `Busc…` | hint inteiro: `Buscar por nome, slug ou ID...` (aceite 31) |

O cabeçalho empilhou como a Causa B previa: título, busca em largura cheia, e a linha de
ordenação com o alternador Grade/Lista abaixo.

## `02_editor_portao_android.jpg` — atende o **aceite 35-A**

O editor no mesmo aparelho. Em vez do construtor espremido, o portão da F1b: o ícone de
monitor, "A tela está pequena demais para o construtor", a explicação, e os dois botões —
**"Ver conteúdo"** e **"Voltar aos conteúdos"**.

**Nenhum pedaço do construtor aparece** — nem paleta, nem inspector, nem faixa de canvas. É
o que o aceite exige: o par de fotos da `rodada_00` mostrava o canvas ausente com os painéis
brigando pela largura; aqui não há painel nenhum para brigar.

## `00_projetos_android.jpg` — atende o **aceite 33**

A home de projetos, com os dois cartões ("Portal da RE" e "Megazord - App RE") empilhados e
legíveis: capa, nome, descrição e a linha de contagem (`1 categoria · 0 conteúdos`). Nenhum
conteúdo de cartão cortado.

## `03_preview_android.jpg` — a rota `/preview`, e o que ela mostra do 4.1, 4.2 e 4.3

O conteúdo "home de IR" renderizado em `hml.driva.duckdns.org/pr…`: faixa laranja com
"Texto", a `image` do perfume carregada pelo proxy de mídia do item 39, e o "Botão".
O renderer é o mesmo `sdui_flutter` que o app cliente usará — é isto que o preview promete.

**O 4.2 está resolvido, e a resposta é "não é problema".** A barra da base (`‹ ○ |0|`) é a
**barra de navegação do Android**, do sistema. A rota `/preview` nasce sem chrome (é irmã do
`ShellRoute`, não filha dele), e a foto confirma: não há nada nosso ali.

> **Decisão do dev humano (2026-08-16), sobre esta foto:** a barra do Android **não
> incomoda e não vira tarefa** — um app de verdade também a tem. O que denuncia o navegador
> é a **barra de endereços**, e é só ela que precisa sair.

**O que a foto mostra dos outros dois, e que vira aceite "antes" das fases F2b e F2c:**

| Item | O que aparece na foto | Fase que resolve |
| --- | --- | --- |
| 4.1 | a pílula `Verificado às 13:10 · toque para atualizar`, flutuando sobre o conteúdo | **F2b** — pull-to-refresh no lugar dela |
| 4.3 | `hml.driva.duckdns.org/pr…` na barra de endereços do Chrome | **F2c** — manifest PWA em `standalone` |

**O objetivo que este print define, e que limita o escopo das duas fases:** o preview é
*"um preview de como irá ficar no app de verdade — só isso"*. Não é o ambiente de teste
real; esse será o app nativo apontando para HML. Fases que passem disso estão fora do
recorte.

## O que estas fotos **não** provam

- **35-B / 35-C / 35-D** — que "Ver conteúdo" leva ao conteúdo certo, e que o passeio
  lista → portão → preview fecha sem beco. São **pares** de fotos, e aqui há uma só de cada
  tela. Continuam pendentes da rodada de E2E.
