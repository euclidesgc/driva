# Rodada 02 — o teste de campo do PWA, 2026-08-16

Aparelho Android do dev humano, contra homologação (`hml.driva.duckdns.org`).

## `00-pwa-instalado-alvo-errado.jpeg`

O `/preview` instalado **antes** do PR #150. A tela está limpa — sem barra de endereços — e
foi por isso que o aceite da F2c passou. **A barra de status é azul (`#0175C2`)**: o
`theme_color` do `manifest.json`, o alvo do **editor**, com `scope: "/"`. O nome embaixo do
ícone era `driva`.

O aceite da D31 não conseguia ver esta falha, porque `scope: "/"` também cobre `/preview` e
o print do cenário quebrado é idêntico ao do correto.

## `02-pwa-instalado-alvo-correto.jpeg`

O mesmo `/preview` **depois** do #150, com o app removido e reinstalado. **A barra de
status é laranja (`#E8602C`)** — o `theme_color` do `preview_manifest.json`. A cor é a prova
independente de qual manifest o sistema usou: ela não depende de ninguém ler o nome do
ícone.

**A régua que fica:** o par 00/02 é o exemplo de por que "a tela ficou limpa" não é aceite.
O que separa os dois prints é uma cor de 40 px de altura.

## `01-top-bar-corta-acao-primaria.jpeg`

A tela de projetos no mesmo aparelho. A top bar mostra `Driva Builder`, `Arquivados (2)` e
o `+ Novo projeto` **cortado ao meio**; o indicador de status e o botão de tema estão fora
da tela. É a causa que a **D35** endereça, e o "antes" da tarefa 1 da F3.
