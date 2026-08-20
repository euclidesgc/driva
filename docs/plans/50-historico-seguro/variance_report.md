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
