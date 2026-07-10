# Variance Report — Item 10 / Tela do projeto (docs/08)

Desvios do plano durante a implementação do fluxo Projetos→Categorias→Conteúdos
(P1/P2/P3). Cada um traz motivo, decisão e status de confirmação.

## VR-08-01 — `categories_module` fundido no `contents_module`

**Plano.** A P1 previa um `categories_module` **separado** (via skill
`criar-modulo`), espelhando o gabarito de módulos.

**O que foi feito.** As categorias (domain + data: entidade `Category`,
contrato, use cases, `CategoryModel`, repositórios impl/fake) vivem **dentro do
`contents_module`**; o `categories_module` foi removido.

**Motivo (decisão do Tech Manager na ausência do humano).** A tela do projeto
(`/projects/:id`) **compõe** árvore de categorias + painel de conteúdos numa só
página. A regra do CLAUDE.md "nenhum módulo importa o interno de outro; barrel
público expõe só rota+DI" torna a composição cross-módulo (presentation de um
lendo domain do outro) inviável sem furar a fronteira. Como categoria só existe
**dentro** do fluxo de organização de conteúdos, fundir os dois num módulo é a
simplificação que respeita a regra (um módulo, camadas limpas) em vez de criar
duas fronteiras que precisariam ser furadas.

**Status.** Não fere nenhuma regra do CLAUDE.md; QA confirmou camadas limpas.
**Desvio do plano escrito → aguarda confirmação do humano.** Reversível (dá para
extrair `categories_module` de volta se o time preferir), mas sem ganho claro.

## VR-08-02 — Pseudo-nó "Não categorizados" → "Todos os conteúdos"

**Contexto.** A árvore da tela do projeto (fiel ao protótipo) tinha um nó fixo
"Não categorizados" com filtro `categoryId = null`.

**Problema (achado do QA, severidade alta).** `Content.categoryId` é NOT NULL
(default "Geral" semeada por projeto), então **não existe conteúdo sem
categoria**; o rótulo mentia, duplicava/confundia com a categoria "Geral" real
da API, e clicá-lo listava o **projeto inteiro**, não "os sem categoria".

**Decisão.** O nó virou **"Todos os conteúdos"** (filtro "ver tudo",
`select=null`, `Icons.apps_outlined`, negrito permanente, separado por divisor,
sem ações de edição, contagem = soma real das categorias), selecionado por
padrão. Semântica honesta e que **antecipa o item 12 do roadmap** ("Todos" como
primeiro item). "Geral" e demais categorias reais são os nós abaixo.

**Nota.** O `.dc.html` do protótipo ainda diz "Não categorizados" (foi desenhado
antes do modelo com `categoryId` obrigatório) — seguimos a semântica correta do
dado, não o rótulo do protótipo. Alinhamento técnico, **sem aprovação pendente**;
registrado para ciência.
