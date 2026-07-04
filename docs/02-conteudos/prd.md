# PRD — Conteúdos (rename Página → Conteúdo)

> Redigido em 2026-07-02 a partir da `specs.md` + respostas do dev às 7 pendências do discovery. **Aguardando aprovação do dev.** Dono: PM. "Pronto" = bater com este documento. Nada de `plan.md`/implementação antes do OK humano.

## Resultado esperado

O driva passa a falar "conteúdo" no lugar de "página" em toda a stack, sem perder nenhuma capacidade atual. Um usuário abre o editor no Chrome, vê a lista de **Conteúdos**, cria um conteúdo informando **Nome** e **Descrição** (o `slug` é derivado do nome ao vivo, editável e garantidamente livre), edita a árvore SDUI como antes, salva, recarrega e reencontra tudo. Cada card mostra `slug` em destaque (a referência que o dev usará no código) e o `id` de suporte. Os dados reais que já existem em hml/prod são migrados de `page` para `content` sem perda, com o `slug` semeado do antigo `screenTarget`.

## Fronteira de escopo (o dev pediu destaque)

**Dentro:** rename página→conteúdo em `sdui_core` (`PageSpec`→`ContentSpec`, `parsePageSpec`→`parseContentSpec`, `kind:"page"`→`"content"`, remove `screenTarget`, adiciona `slug`/`description`), `sdui_flutter` (nomenclatura do renderer; **reserva** o nome `DrivaContent` como fachada pública — só nome/contrato), `driva_editor` (`pages_module`→`contents_module`, rotas `/pages`→`/contents`, formulário Nome+Descrição+slug, card novo, textos pt-BR), `backend` (`/v1/pages`→`/v1/contents`, Prisma `Page`→`Content`, CRUD, `@@unique([projectId, slug])`, `409`), migração destrutiva versionada, fixtures/testes/docs.

**Fora (próximo incremento):** o **serving real por slug** ao app cliente — endpoint público de leitura + o fetch dentro do pacote que resolve `DrivaContent(slug:)` em runtime. A **resolução de projeto no pacote** (`Driva.init(projectId:)`) também fica para lá; aqui só registramos a intenção. `DrivaContent` nasce como fachada reservada (nome + contrato de dados), **sem** implementação de rede. Não se adiciona rota `by-slug` a menos que o E2E manual precise de um caminho de leitura — se precisar, mínimo e marcado como provisório.

## Modelo de identificação

| Campo | Regra |
|---|---|
| `id` | CUID2 (`@default(cuid(2))`) para **novos** registros; **UUIDs existentes são mantidos** (não regerar). Opaco, imutável. Card mostra como "ID de suporte" |
| `slug` | Referência do dev. `^[a-z][a-z0-9-]*$`. Único por projeto — `@@unique([projectId, slug])` (garantia dura no Postgres). Editável sempre; frontend deriva do nome ao vivo e **sugere um slug livre**; backend responde `409` em corrida. Em destaque no card |
| `name` | Obrigatório. Rótulo humano |
| `description` | Opcional, texto livre |

## Caminho feliz

1. Lista de conteúdos carrega (`GET /v1/contents`) → grid de cards (slug em destaque, id de suporte, nome, descrição).
2. "Novo conteúdo" → **Nome** (obrigatório) + **Descrição** (opcional). Ao digitar o nome, o `slug` é derivado ao vivo (slugify), editável, e o front sugere uma variante livre se houver colisão (`home` → `home-2`).
3. `POST /v1/contents` → backend grava com `id` CUID2 e valida a unicidade do slug (`409` se corrida) → abre o editor.
4. Editor carrega o spec (`GET /v1/contents/:id`, `parseContentSpec`) → os 4 painéis renderizam (comportamento SDUI inalterado).
5. Editar a árvore/props → preview reflete no mesmo frame; estado "não salvo".
6. Ctrl+S / Salvar → `PUT /v1/contents/:id` → indicador "salvo".
7. Editar o slug depois → aviso não-bloqueante ("o slug é sua referência no código; mudá-lo quebra apps que já o usam"); salva se válido e livre.

## Exceções e casos de borda

| Caso | Comportamento |
|---|---|
| Slug em uso no projeto (corrida) | Backend `409` → editor mostra o slug ajustado sugerido e explica ("slug já em uso neste projeto") |
| Slug inválido no formato | Validação no cliente antes de salvar (`^[a-z][a-z0-9-]*$`); mensagem clara |
| Backend fora do ar | `NetworkFailure` → mensagem + retry; documento em memória preservado |
| Conteúdo inexistente (`/contents/x/edit`) | `NotFoundFailure` → tela de erro tratada, link de volta à lista |
| Spec inválido vindo do backend | `ValidationFailure` (via `parseContentSpec`) → erro descritivo, sem crash |
| id malformado na URL | fallback de rota, sem crash |
| Conteúdo vazio (root sem filhos) | estado vazio com orientação |
| Editar slug de conteúdo já usado por um app | Permitido (I4 revisita trava no publish); aviso não-bloqueante sempre visível |
| Fechar/recarregar com alterações não salvas | Sem auto-save; indicador de "não salvo" visível |

## Plano de migração destrutiva (o dev pediu destaque — risco + checklist)

Decisões travadas: **adotar Prisma Migrate versionado agora** (a migração do rename é a baseline versionada; encerra o `db push`). Semear `slug` de `slugify(screenTarget)`, sanitizando o que não bate `^[a-z][a-z0-9-]*$`, com sufixo em colisão por projeto (`home`, `home-2`). Manter UUIDs existentes; só novos nascem CUID2. **Reescrever o JSONB** de cada registro (`kind:"page"`→`"content"`, remover `screenTarget` do envelope), não só as colunas.

**Risco:** operação destrutiva e irreversível em prod/hml (drop de `screenTarget`, `@@unique` nova, reescrita de JSONB linha a linha). Exige **backup + janela de manutenção**.

**Checklist (a detalhar no `plan.md`):**
1. Backup do Postgres (prod e hml) antes de qualquer migração.
2. Introduzir Prisma Migrate; primeira migration = baseline do estado atual (`db push` → migrations).
3. Migration de rename: tabela `pages`→`contents`; add `slug`, `description`; add `@@unique([projectId, slug])`; drop `screenTarget`.
4. Data migration: para cada registro, `slug = dedupe(slugify(screenTarget), projectId)`; reescrever o JSONB do spec (`kind`, remover `screenTarget`); manter `id` (UUID legado) intacto.
5. Validar contagem de linhas e amostra de specs pós-migração; rodar `parseContentSpec` sobre uma amostra.
6. Janela: hml primeiro, validação manual, depois prod.
7. Rollback documentado (restaurar backup) caso a validação falhe.

## Analytics

Nenhum evento novo. Registrar explicitamente em ANALYTICS.md (rename não introduz telemetria).

## Erros monitorados

As 4 redes globais (`bootstrap.dart`) seguem cobrindo o imprevisto; `Failure` tipadas cobrem o previsto (incluindo o novo `409`/conflito de slug, que deve virar uma `Failure` tipada em `core/error/` e ser traduzida na camada data). ERROR_LOGS.md documenta o novo caminho de conflito de slug.

## Testes que cada etapa pede

- **Kernel (`sdui_core`)**: `parseContentSpec` com fixtures válidas/ inválidas (incluindo `kind:"content"`, ausência de `screenTarget`, presença de `slug`); serialização round-trip; regressão dos nomes antigos removidos.
- **Renderer (`sdui_flutter`)**: contrato catálogo↔registry inalterado; fixture ponta a ponta com o novo envelope; presença da fachada `DrivaContent` (nome/contrato, sem rede).
- **Editor (`driva_editor`)**: bloc_test dos cubits (lista e editor renomeados); derivação do slug ao vivo; tratamento de `409`; widget tests dos estados; golden do card/formulário novos — **por último**.
- **Backend**: unicidade `@@unique` (dois inserts mesmo slug/projeto → `409`); slug de projetos diferentes coexistem; `id` novo = CUID2; teste da data migration (page→content, slug do screenTarget, JSONB reescrito, colisão sufixada).
- **E2E manual**: roteiro no `test_plan.md`; quem testa é o dev.

## Critérios de aceite

1. Roteiro do caminho feliz completo sem erro no console, com o vocabulário "Conteúdo/Conteúdos" na UI (pt-BR aprovado).
2. Criar conteúdo com Nome+Descrição; slug derivado, editável e livre; `409` tratado com slug sugerido.
3. `@@unique([projectId, slug])` bloqueia duplicata no mesmo projeto; slugs iguais em projetos diferentes coexistem.
4. `id` de novos registros é CUID2; UUIDs legados preservados após a migração.
5. Migração aplicada em hml e validada (contagem + amostra `parseContentSpec` + JSONB sem `screenTarget`/`kind:"page"`) antes de prod; backup feito.
6. Nenhuma referência a `PageSpec`/`parsePageSpec`/`screenTarget`/`/v1/pages`/`kind:"page"` remanescente no código, docs, fixtures e testes (rename completo).
7. `DrivaContent` existe como fachada pública reservada (nome + contrato), sem implementação de rede; serving por slug e `Driva.init(projectId:)` registrados como escopo do próximo incremento.
8. `flutter analyze` verde; baterias de teste verdes; docs vivas em dia (DoD).
