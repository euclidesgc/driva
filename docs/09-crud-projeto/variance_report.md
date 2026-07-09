# Variance Report — CRUD de Projeto (docs/09)

Registro de desvios do plano/PRD durante a implementação. Cada desvio traz o
motivo, a decisão e o que aguarda confirmação do humano.

## VR-01 — `createdAt` incluído na resposta de lista (`GET /v1/projects`)

**Contexto.** O PRD rascunhado definia a lista (`GET /v1/projects`) como um
resumo **sem `createdAt`** (só `id, title, description?, imageUrl, updatedAt`),
reservando `createdAt` para o detalhe (`GET /:id`). A camada domain (F3),
porém, foi modelada com uma **entidade única `Project` sem split
summary/detail**, em que `createdAt` é **obrigatório** — logo o payload de
lista do PRD não seria parseável pelo `ProjectModel` (F4).

**Alçada.** Refinamento técnico de contrato, não ambiguidade de produto: as
três saídas possíveis (A: `createdAt` nullable no domain; B: split
`ProjectSummary`/`Project`; C: backend inclui `createdAt` na lista) satisfazem
igualmente a necessidade do produto (cards com título/descrição/imagem).
Decidido pelo Tech Manager na ausência do humano (que autorizou construir as
partes não-design), com registro aqui e sinalização para revisão.

**Decisão: Opção C** — `GET /v1/projects` passa a incluir `createdAt`.
Racional:
- `createdAt` é um escalar trivial; todo projeto tem um. Nullable no domain
  (Opção A) seria uma inverdade que espalharia null-checks pela aplicação.
- Não há assimetria de peso entre lista e detalhe que justifique um split
  (Opção B) — diferente de `contents_module`, onde `ContentSpec` é pesado.
- O backend (F2) ainda não estava implementado quando o conflito surgiu →
  custo zero. O `ProjectModel` (F4) já exige `createdAt`, então **já ficou
  alinhado à Opção C sem retrabalho**.

**Efeito nos docs.** `prd.md`: JSON da lista e critério de aceite atualizados
para incluir `createdAt`; lista e detalhe passam a ter a mesma forma.

**Aguardando confirmação do humano.** Baixa relevância — é escolha de
engenharia reversível. Se o humano preferir a lista enxuta (sem `createdAt`),
a saída passa a ser a Opção B (split), com retrabalho no domain/data.
