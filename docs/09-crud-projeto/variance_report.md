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

## Débito de segurança — sem auth real (superfície ampliada)

**Registro do gate CISO (APROVADO com follow-up).** O pipeline de upload de
imagem foi auditado e aprovado (magic bytes próprios não-burláveis, reencode
`sharp`, chave UUID de servidor, serving com `nosniff`, limite em duas camadas,
rate-limit; `pnpm audit` limpo, `multer` sem CVE).

**Follow-up não-bloqueante a priorizar antes de produção multi-tenant / de ligar
`STORAGE_DRIVER=s3`:** a API não tem autenticação — o escopo de tenant vem do
header `x-project-id`, **controlável pelo cliente**. Esse débito já existia em
`contents`, mas com o CRUD de `Project` a superfície **cresceu**: agora um
`x-project-id` forjado alcança operações **destrutivas e de upload**
(`DELETE /v1/projects/:id`, `PUT /v1/projects/:id` com troca de imagem), não só
leitura. `find/update/remove/getImage` de projeto **não filtram por tenant**.
Enquanto não houver auth real, o CRUD de projetos é efetivamente global.
**Ação recomendada:** implementar auth (feature à parte) antes de expor em
produção real ou habilitar o storage S3. Ver [[prd.md]] › Decisão 5.

## Decisão de produto pendente — apagar projeto vs. `onDelete: Restrict` + seed "Geral"

**Achado no E2E.** Com `Project→Category` = `onDelete: Restrict` (Decisão 1) **e**
todo projeto nascendo com a categoria "Geral" na mesma transação, um projeto
recém-criado (só com a "Geral", sem conteúdos) **não pode ser apagado pelo fluxo
normal**: `DELETE /v1/projects/:id` retorna **409** porque ainda tem a categoria
"Geral". O único caminho é drenar: apagar a "Geral" (204, se vazia) e só então o
projeto (204). O E2E cobre os dois caminhos (409 do contrato real + 204 pela
drenagem).

**Consequência de UX.** A home de Projetos não consegue oferecer um "excluir
projeto" que funcione sem antes o usuário apagar manualmente a categoria default
— comportamento pouco intuitivo. A decisão `Restrict` foi tomada **antes** de
existir o seed automático da "Geral"; a combinação das duas não foi reavaliada.

**Opções para o humano decidir:**
1. **Cascade Project→Category** (apagar projeto apaga suas categorias); manter
   `Restrict` só em Category→Content (ou cascatear conteúdos também).
2. Manter `Restrict` e o editor implementar a **drenagem** ao excluir projeto
   (apaga categorias/conteúdos em ordem antes do projeto) — mais lógica no
   cliente, mais requests.
3. Manter como está (excluir projeto exige esvaziá-lo manualmente) — só se for
   intencional proteger contra exclusão acidental.

**Recomendação:** opção 1 (Cascade Project→Category), com confirmação dupla na
UI. Não implementado — **aguarda decisão do humano** (muda schema/migração).

**DECISÃO DO HUMANO (2026-07-09) — exclusão em duas camadas (soft delete):**
descartadas as opções acima em favor de um modelo melhor. Na home, o projeto é
**arquivado** (soft delete: `Project.archivedAt`, some da lista, nada é apagado).
Uma área **"Arquivados"** lista os arquivados, com **Restaurar** (unarchive) e
**Excluir definitivamente** — este último faz o **cascade total** (conteúdos →
categorias → projeto, em `$transaction` no service), com **confirmação dupla** na
UI, e **só é permitido em projeto já arquivado** (`DELETE` em projeto ativo →
409). O `onDelete: Restrict` do schema permanece intacto (a cascata é explícita
no service, só para projeto arquivado). Implementado nesta rodada.

## Auth — decisão do humano (2026-07-09)

**ADIAR e aceitar o débito por ora.** Seguir com `x-project-id` em
homologação/demo interno, com o risco registrado (seção acima). **Limite mantido:
auth entra como feature antes de abrir para usuários reais em produção.** Ver
[[prd.md]] › Decisão 5.

## Storage — estrutura de pastas (decisão do humano, 2026-07-09)

Storage escolhido: **Garage** (`s3.bmjtech.duckdns.org`, já na infra). As mídias
passam a ser organizadas por projeto: a key vira **`<projectId>/midias/<uuid>.<ext>`**
(pasta pelo **id** do projeto — estável e único, não o nome; nome do arquivo em
UUID, exigência do CISO de key não-enumerável). Credenciais só via env no Coolify.
Ligar o S3 depende da auth (ver acima) antes de produção real.
