# Variance report — Loop SDUI fechado

Desvios entre esta entrega e o plano de gaveta
`docs/plans/25-entrega-app-cliente/plan.md`. **Nenhum foi aprovado pelo humano
antes de codar** — a sessão correu com ele ausente. Cada um está aqui para
decisão dele.

## VR-13-01 — O item 24 (publicação e versionamento) não foi feito, e ele é precedência dura do item 25

**O plano diz:** "Precedência dura: item 24 concluído. Sem versão publicada não
há o que servir — este plano chama `ContentVersion`, `publishedVersionId` e
`publishedAt`, que nascem lá." E: "Conteúdo sem publicação → 404 (não revela a
existência do rascunho)."

**O que foi feito:** o endpoint serve o **único** spec que existe hoje — o campo
`Content.spec`, que é o rascunho que o editor está mexendo. Não há como
distinguir publicado de não publicado porque a distinção ainda não existe no
modelo.

**Por quê:** a conversa que originou esta sessão pediu a prova do loop
fim-a-fim (editor → API → app renderizando), e o item 24 é um marco próprio,
com decisões de produto (o que é uma versão, quem publica, como reverte) que
não se resolvem sem discovery. Fazer o 24 inteiro de madrugada, sozinho, seria
pior do que provar o loop e registrar o desvio.

**Consequência prática:** salvar no editor muda o app do cliente no próximo
refresh. Não há rede de proteção — um rascunho quebrado vai ao ar.

**Como fica quando o 24 chegar:** a mudança é localizada em
`PublicService.findBySlug` — em vez de `content.spec`, ler
`content.publishedVersion.spec` e devolver `404` quando não houver publicação. O
ETag passa de `(id, updatedAt)` para `(contentId, version)`, que é imutável, como
o plano prevê. O contrato visto pelo app não muda.

**Recomendação:** não abrir para nenhum cliente real antes do item 24.

## VR-13-02 — O app se chama `driva_demo_app`; o plano previa `apps/driva_showcase`

**O plano diz:** `apps/driva_showcase` — app de exemplo que prova o ciclo
fim-a-fim, consumindo o package `driva_client`.

**O que foi feito:** `apps/driva_demo_app`, que faz o fetch direto (repositório
próprio com Dio), sem o package.

**Por quê:** o `driva_client` é a outra metade do item 25 e depende do item 24
(cache da versão publicada, fallback embarcado). Este app é o **embrião** dele:
provou o caminho `fetch → parseContentSpec → SduiView`, que é exatamente o que o
package vai empacotar. Renomear para `driva_showcase` agora custaria recriar o
boilerplate de plataforma (android/ios/web) por um nome.

**Recomendação:** quando o `driva_client` nascer, este app vira o consumidor
dele — aí é a hora de decidir se renomeia ou se `driva_showcase` é outro app.

## VR-13-03 — Chave publicável entregue sem rotação

**O plano diz (D1):** chave gerada na criação do projeto, com rotação via
`POST /v1/projects/:id/rotate-key`.

**O que foi feito:** a chave nasce com o projeto (`generatePublishableKey`, 32
bytes aleatórios em base64url) e os projetos existentes receberam uma na
migration. **Não há rotação nem revogação.**

**Por quê:** rotação sem auth de editor (item 26) é meio caminho — hoje qualquer
um que alcance a API poderia chamar o endpoint de rotação. Entregar a geração
(que fecha o buraco de "endpoint sem barreira nenhuma") sem a rotação é o degrau
que faz sentido isolado.

**Recomendação:** rotação entra junto com o item 26.

## VR-13-04 — Sem rate limit na rota pública

O plano cita rate limit. Não foi feito. `@nestjs/throttler` já está nas
dependências do backend, então é barato — mas envolve decidir a política (por
chave? por IP? quanto?), que é decisão de produto/CISO.

## O que **não** desviou

- Controller e service separados em `backend/src/public/` (D2 do plano).
- Chave publicável identificando o projeto, no header (D1).
- `ETag` + `304` + `Cache-Control` (D3).
- `404` genérico para chave inválida — não revela existência (D3).
- `parseContentSpec` como único portão de entrada de spec no app cliente.
- `allowedHeaders` do CORS atualizado para o header novo — o plano marca esse
  como "ponto fácil de esquecer".
