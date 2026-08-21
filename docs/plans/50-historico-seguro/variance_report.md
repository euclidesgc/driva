# Variance report — item 50 (histórico seguro de publicação)

Desvios em relação ao recorte do `plan.md`, com a decisão do dev humano que os autorizou.

---

## VR-50-01 — A comparação mostra os dois previews, mas sem marcadores sobrepostos

**O plano dizia:** T5, item 2 — "Preview e arvore exibem os mesmos marcadores".

**O que foi feito:** o diálogo de comparação exibe um preview inerte de cada lado (base à
esquerda, candidata à direita, reaproveitando o `VersionSnapshotPreview` da T3) e os
marcadores ficam na lista de diffs ao lado — nenhum badge é desenhado por cima do
renderer.

**Por quê:** sobrepor marcador ao desenho de cada nó exige mapear nó → retângulo na tela,
o que só o `sdui_flutter` sabe fazer. Isso é trabalho de renderer, num pacote que os apps
dos clientes consomem, e não cabe na fatia de apresentação da T5. A entrega mantém o
"lado a lado" que o plano promete ao usuário sem tocar no renderer.

**Aprovado pelo dev humano** em 2026-08-20, na revisão da primeira volta da T5.

---

## VR-50-02 — O rótulo dos nós exclusivos nomeia a base exibida, não "o rascunho"

**O plano dizia:** DoD da T5 fixa as strings `Somente no rascunho` e `Somente na versão`.

**O que foi feito:** `Somente na versão` não muda. `Somente no rascunho` — e os demais
textos que citam o rascunho — passam a nomear a base que está de fato à esquerda: com a
base em "Rascunho", a redação é a original; com a base trocada para "No ar", o rótulo
nomeia a versão publicada. O critério vira "o rótulo nomeia a base exibida".

**Por quê:** o item 1 da T5 permite trocar a base para a versão no ar, e a string fixa
colide com isso — a tela afirmaria "somente no rascunho" sobre nós que não estão no
rascunho. Falha silenciosa na tela é exatamente o que este item existe para matar.

**Aprovado pelo dev humano** em 2026-08-20, sobre achado do supervisor de DoD da T5.

---

## VR-50-03 — O critério "a cópia pode criar erro novo" era inalcançável

**O plano dizia:** T5, item 5 — "Reexecutar diagnosticos apos copia; **se criar erro**, mostra-lo
no fluxo normal de publicacao, sem desfazer a acao escondido."

**O que foi feito:** o item passou a cobrar o que é observável — a cópia não é desfeita por
baixo dos panos, e o bloqueio de publicação reflete os diagnósticos do documento resultante.

**Por quê:** `copyComparableNodeProperties` substitui só `properties`, e `diagnoseTree`
(`packages/sdui_core/lib/src/diagnostics/diagnose_ops.dart`) só examina `type`, o tipo do pai e
`child`/`children`. Uma cópia de propriedades não tem como produzir um diagnóstico que já não
existisse: o estado "erro novo depois da cópia" é inalcançável, e nenhum teste consegue
observá-lo. O supervisor de DoD provou a insensibilidade congelando `EditorReady.diagnostics`
num campo estático — a negação literal de "são reexecutados" — e o teste da tarefa continuou
verde, embora a mesma mutação derrubasse seis testes pré-existentes. A única asserção capaz de
distinguir "recalculado" de "congelado" seria `expect(f(x), f(x))`, proibida pelo próprio
critério de prova por mutação.

**Corrigido pelo tech-manager** em 2026-08-20, como correção de DoD errado — não como
afrouxamento para a tarefa passar. O trabalho já cumpria as duas metades verificáveis, ambas
provadas por mutação.


---

## VR-50-04 — O modal de comparação foi substituído por um modo do editor

**O plano dizia:** T5 inteira — a comparação como diálogo (`VersionCompareDialog`), com dois
previews, listas de nós exclusivos e o botão de cópia dentro dele.

**O que foi feito:** a comparação virou um **modo do editor**, com dois mocks no canvas (o
rascunho ao vivo à esquerda, a versão escolhida à direita), marcadores no Inspector e o modal
apagado. O redesenho está planejado em [`plan_t5b.md`](plan_t5b.md) e entregue na F1
(PR #199).

**Por quê:** o dono testou a T5 entregue e disse que não era o que tinha em mente. Nas palavras
dele, em 2026-08-20: *"exibir outro mock na janela do builder, ao lado do existente, onde o da
esquerda é o atual e o da direita é a versão que o user está comparando"*. Usar revelou o
defeito do desenho: comparar tirava o usuário do editor, e a cópia de propriedade acontecia
longe do canvas onde o resultado aparece.

**Pedido pelo dono do produto** em 2026-08-20. Não é correção de erro de execução: a T5 cumpria
o plano; o plano é que descrevia a superfície errada.

---

## VR-50-05 — A saída do modo não se chama "Cancelar"

**O plano dizia (pedido do dono):** *"Para sair desse modo o user salva ou cancela."*

**O que foi feito:** o botão chama-se **"Fechar comparação"**.

**Por quê:** "Cancelar" promete reverter, e nada é revertido — as propriedades já trazidas da
versão continuam no rascunho, desfazíveis uma a uma por `Ctrl+Z` como qualquer edição manual.
Um botão que promete desfazer e não desfaz é a mesma classe de falha silenciosa que o item 50
existe para matar. Registrado como decisão da D3 do `plan_t5b.md`.

**Desvio proposto pelo tech-lead e mantido pelo tech-manager**, comunicado ao dono em
2026-08-20. Se ele preferir que cancelar reverta de fato o que foi copiado durante o modo,
isso é implementável e vira decisão dele.

---

## VR-50-06 — O toggle "base: rascunho / no ar" foi removido

**O plano dizia:** T5, item 1 — "A base default é o rascunho; quando houver, o usuário pode
trocar para a versão no ar". O VR-50-02 acima nasceu desse mesmo item.

**O que foi feito:** o toggle não existe no modo in-canvas. O lado esquerdo é sempre o canvas ao
vivo. Com isso, o VR-50-02 fica superado — não há mais base variável para o rótulo nomear.

**Por quê:** consequência estrutural do VR-50-04. O lado esquerdo passou a ser o editor de
verdade, e não um painel que pode exibir qualquer spec. Comparar a versão no ar contra uma
versão antiga, sem passar pelo rascunho, deixa de ter porta própria — continua sendo possível
ver as duas pelo histórico, uma de cada vez.

**Resolvido em 2026-08-20 — decisão do dono:** a perda está confirmada. Em troca, o modo ganha
a legenda `Rascunho` no lado esquerdo e o botão **`Voltar à versão publicada`**, que deixa o
rascunho idêntico à versão publicada — com confirmação nomeando o que se perde e uma única
entrada de undo. Junto veio a decisão de vocabulário: "no ar" sai dos rótulos da UI — os pares
são **Publicado/Despublicado** (e `Publicada` para versão). Desenho na D6 do
[`plan_t5b.md`](plan_t5b.md), tarefas T5b.17–T5b.20 (fase F2b).

---

## VR-50-07 — O E2E do item deixa de ser script e vira roteiro manual curto

**O plano dizia:** T7 — criar `e2e_hml.sh`, `e2e_shots.sh` e `e2e_drive.mjs` no padrão do item
24, com o driver visual capturando desktop, overflow compacto, ver, comparar, seta, cancelar,
carregar e publicar.

**O que foi feito:** a T7 passa a ser um roteiro manual curto, cobrindo só o que a pirâmide de
testes não alcança. A cobertura de fluxo, cubits, marcadores e undo passou a ser widget e
unitário, escrita junto de cada fase.

**Por quê:** mudança de política do repositório, decidida pelo dono em 2026-08-20 e registrada
no `CLAUDE.md` — unitário e widget primeiro, E2E por exceção com três critérios de admissão. A
decisão veio da constatação de que cada feature carregava scripts caros para provar o que um
`bloc_test` prova mais barato e mais cedo. Vale para o repositório inteiro, não só para este
item.

**Decisão do dono do produto** em 2026-08-20.

---

## VR-50-08 — O limiar de colapso da barra de topo subiu de 840 para 893

**O plano dizia:** T1 — decisão registrada do dono fixou `AppSizes.topBarActionsFitWidth = 840`
(cruzamento medido em ~794px + 46px de folga).

**O que foi feito:** o token passou a **893** (cruzamento em ~847px + os mesmos 46px).

**Por quê:** o item 53 acrescentou "salvar e marcar no histórico" como sétima ação da barra, e a
`Row` passou a estourar 6,6px em 840 — a cerca calibrada na T1 pegou na hora. **O custo é real e
está registrado no dartdoc do token:** quem tiver a janela entre 840 e 893 passa a ver a barra
colapsada. É também a evidência objetiva de que a barra chegou ao teto de ações enfileiradas,
que é o que o **item 52** do roadmap trata.

**Consequência de uma feature pedida pelo dono**, comunicada a ele em 2026-08-20.

---

## VR-50-09 — E2E suspenso: a T5b.16 (roteiro manual) morre

**O plano dizia:** T5b.16 — roteiro manual curto de quatro passos em homologação, com prints em
`docs/50-historico-seguro/evidencias/rodada_01/`, atestado pelo dev humano. Já era o formato
reduzido que o VR-50-07 registrou.

**O que foi feito:** nenhum E2E — nem script, nem roteiro. Dois dos quatro passos viraram teste
de widget na bateria da T5b.20 (recarregar a página cai no editor sem o modo; fechar a
comparação depois de duas cópias mantém as duas, com `Ctrl+Z` desfazendo uma a uma). Os outros
dois — fidelidade de fonte/imagem entre dois `SduiView` reais e digitação instantânea sob carga
real de navegador — ficam sem cobertura.

**Por quê:** decisão do dono em 2026-08-20, para o repositório inteiro: testes E2E estão
suspensos; a prova é unitário, widget e, no máximo, golden. Registrada no `CLAUDE.md` (Método
de trabalho). O risco que fica descoberto é conhecido e aceito — o "tofu" do item 24 foi um
defeito que só o navegador real mostrou.

**Decisão do dono do produto** em 2026-08-20.
