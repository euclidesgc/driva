# WidgetMill — Roadmap de Execução (fases → tarefas)

> Decomposição executável das 5 milestones definidas na [elaboração §4](elaboracao-construcao.md). Cada fase vira um conjunto de tarefas com critério de aceite (DoD). O plano **detalhado** (TDD, passo a passo) de cada fase vive em `docs/superpowers/plans/`. Este documento é o índice de alto nível + log de progresso.
>
> Ordem de construção: **M0 → M1 → M2** na fatia vertical; **M3** pode correr em paralelo após o M0; **M4** integra tudo.

## Estado da toolchain (verificado em 2026-06-14)

| Ferramenta | Versão | Observação |
|---|---|---|
| Node | 18.19.1 | OK p/ o kernel (Vitest ≥18.18). **Node 20 recomendado** p/ os apps (Next/NestJS) no M1+ |
| pnpm | 10.24.0 | workspace TS |
| Docker | 29.4.3 | Postgres + Redis (M3) |
| Flutter | via puro `3.38.6` | fora do PATH; relevante a partir do M1 |

---

## M0 — Kernel & Fundação  *(plano §12 fase 1)*

**Meta:** o `packages/spec` (Zod) como única fonte de verdade — 14 primitivos + tipos complexos + eventos/ações + `specVersion`, com fixtures golden e testes. Mais a fundação do monorepo.

**DoD:** `pnpm test` valida todos os fixtures; um spec inválido é rejeitado com erro legível.

| Tarefa | Descrição | Saída |
|---|---|---|
| T0.1 | Fundação do monorepo | `pnpm-workspace.yaml`, root `package.json`, `.gitignore`, `.nvmrc`, `.editorconfig`, `.env.example`, READMEs/`.gitkeep` por diretório, `infra/docker-compose.yml` |
| T0.2 | Esqueleto do `packages/spec` | `package.json` (`@widgetmill/spec`), `tsconfig.json`, `vitest.config.ts`, `src/`, `fixtures/` |
| T0.3 | Helpers de binding e tipos primitivos | `Bindable`, `Color`, helpers de enum — testados |
| T0.4 | Tipos complexos do núcleo | `EdgeInsets`, `TextStyle` — testados |
| T0.5 | Nós do núcleo + união | `Text`, `Column`, `Container` + `Node` (lazy/recursivo) — testados |
| T0.6 | **Fatia verde**: 3 fixtures golden | `container>column>text` validado pelo Zod — *checkpoint vertical* |
| T0.7 | Tipos complexos restantes | `BoxDecoration` (border, boxShadow, gradient, borderRadius), `Alignment`/`AlignmentDirectional`, `constraints` |
| T0.8 | Nós restantes (11) | Row, Stack(+Positioned), Image, Icon, Button, SizedBox, Padding, Center, Expanded, Flexible, Spacer, GestureDetector |
| T0.9 | Eventos & ações | `Events` + `Action` (navigate, openUrl, goBack, showDialog, track, custom) |
| T0.10 | `WidgetSpec` de topo | `specVersion`, `slug`, `name`, `kind`, `propsSchema` (PropDef), `tree` + fixture `primary_button` |
| T0.11 | Revisão da fase | KISS/DRY, modularização, classes pequenas; atualizar log + commit |

Plano detalhado: [docs/superpowers/plans/2026-06-14-m0-kernel.md](superpowers/plans/2026-06-14-m0-kernel.md)

---

## M1 — Renderer & Preview  *(plano fases 2–3 · depende de M0)*

**Meta:** `sdui_flutter` (renderer real) + `sdui_preview` (app Flutter Web com bridge `postMessage`).

**DoD:** WS-0..WS-2 verdes; editar o JSON na página muda o preview com fidelidade; troca de dispositivo muda o tamanho.

| Tarefa | Descrição |
|---|---|
| T1.1 | `flutter/sdui_flutter`: models `freezed`/`json_serializable` espelhando o Zod |
| T1.2 | Registry `type → builder` + builders dos 14 primitivos |
| T1.3 | Resolução de binding `{{...}}` e tokens `$...` em runtime |
| T1.4 | Dispatcher de ações (navigate/openUrl/goBack/showDialog/track/custom) |
| T1.5 | **Testes golden** consumindo `packages/spec/fixtures` (trava o drift Zod↔Dart) — **WS-0** |
| T1.6 | `flutter/sdui_preview`: app Web que escuta `postMessage` e re-renderiza — **WS-1** |
| T1.7 | Bridge: validação de `origin`, devolve eventos (altura, tap, erro) ao editor |
| T1.8 | Build do preview → `apps/web/public/preview/` (mesma origem) |
| T1.9 | Página Next mínima: `<iframe>` + `<textarea>` JSON + moldura de dispositivo — **WS-2** |
| T1.10 | Revisão da fase |

---

## M2 — Editor (Builder)  *(plano fases 4–7 · depende de M1)*

**Meta:** editor visual com Puck, Layers, Inspector gerado e binding.

**DoD:** WS-3 verde; montar o `primary_button` inteiro no editor, com binding, e ver no preview.

| Tarefa | Descrição |
|---|---|
| T2.1 | `apps/web`: bootstrap Next (App Router, TS), Zustand+Immer+zundo |
| T2.2 | Palette (Puck) dos 14 primitivos + canvas com aninhamento (Slots) |
| T2.3 | Tradutor `packages/spec/src/puck` (`specToPuck`/`puckToSpec`) — round-trip property-based — **WS-3** |
| T2.4 | Field descriptors em `packages/spec/src/descriptors` (1 por primitivo) |
| T2.5 | Inspector genérico: `type → componente de campo` (RHF+Zod), gerado por descriptor |
| T2.6 | Editor de eventos/ações (lista ordenada) |
| T2.7 | Layers sincronizada (undo/redo via zundo) |
| T2.8 | Definição de props públicas + binding `{{...}}`; preview embarcado com debounce |
| T2.9 | Revisão da fase |

---

## ⚠️ Pendências e problemas em aberto (antes do M3)

> **M3 está postergado.** Estes itens devem ser resolvidos/decididos antes de iniciar o backend. Lista a **refinar com o usuário na retomada** (há problemas específicos a levantar).

**Verificação**
- Verificação visual do **editor Puck (WS-3)** no navegador (drag-drop, Inspector, undo/redo, sync do preview) — ainda não exercida em browser. (WS-0..WS-2 já ok.)

**Ferramental — gaps de configuração**
- **ESLint não configurado**: os scripts `lint` (`eslint src` no kernel; `next lint` no web) referenciam ESLint, mas **não há config** → `pnpm lint` falha hoje. Adicionar flat config (ou ajustar scripts).
- **Turborepo ausente**: `turbo.json` não existe (scripts usam `pnpm -r`). Opcional; decidir se entra agora.
- **CI**: sem pipeline (lint/test/build). Recomendado antes de crescer.

**Editor (M2) — follow-ups funcionais**
- **Editor de ações/eventos (T2.6)**: `onTap`/`onPressed` não editáveis na UI (só via JSON).
- **Editores ricos de tipos complexos**: EdgeInsets de 4 lados (hoje só `all`), color picker (hoje texto hex), BoxDecoration completo (hoje `color`+`borderRadius`).
- **Props públicas + binding-picker**: declarar `propsSchema` e ligar props via UI (hoje binding só digitando `{{prop}}`).
- **`constraints` do Container** não exposto no Inspector.
- **Slot de filho único** (container/center/…): o Puck permite soltar vários; `puckToSpec` usa o primeiro. **Já há feedback** (erro de montagem via `diagnose`) — falta a *restrição* (impedir o drop) e o mesmo para múltiplas raízes (hoje sinalizadas + `column` implícito no preview).

**Renderer / contrato**
- **Design system / tokens (`$token`)**: resolução existe no renderer, mas não há catálogo nem UI de tokens.
- **Cobertura golden**: ampliar fixtures (mais primitivos/edge cases) no cross-check Zod↔Dart.

---

## M3 — Backend: identidade, RBAC, workflow, versionamento  *(plano fases 8–9 · depende de M0)*

**Meta:** NestJS + Prisma + Better-Auth + Casbin; multi-tenant, workflow e versionamento imutável.

**DoD:** WS-4 + fluxo `draft→in_review→approved→published` com papéis distintos; ação fora do papel é negada; publicar gera `version = current+1` imutável.

> **Seam pronta (2026-06-15):** o editor já salva/versiona contra a interface `apps/web/lib/widget-repo/WidgetRepository` (hoje `InMemoryWidgetRepository`). T3 deve fornecer uma `ApiWidgetRepository` que chama o backend — trocar a instância default em `widget-repo/index.ts` é o único toque na UI. O modelo de dados (versão imutável, status `draft`/`published`, "usada" = última publicada) já está no kernel (`history/`).

| Tarefa | Descrição |
|---|---|
| T3.1 | `infra/prisma/schema.prisma` (modelo do plano §10) + migrations |
| T3.2 | `infra/prisma/seed.ts`: plataforma + primitivos + 1 projeto + 5 papéis + transições de workflow |
| T3.3 | `apps/api`: bootstrap NestJS + Prisma module |
| T3.4 | Better-Auth (sessão/JWT backend-owned) |
| T3.5 | Casbin: 5 papéis → permissões em notação de ponto, escopadas por `project_id` |
| T3.6 | Multi-tenancy: guard que filtra todo acesso por `project_id`; primitivos read-shared |
| T3.7 | Draft com lock otimista (`base_version`) — **WS-4** |
| T3.8 | Workflow state machine DB-driven (`workflow_transitions`) |
| T3.9 | Publicação → linha imutável em `widget_versions` (`version = current+1`) |
| T3.10 | `project_routes` (CRUD) p/ alimentar `navigate` + audit log |
| T3.11 | Revisão da fase |

---

## M4 — Catálogo & Polimento  *(plano fase 10 · depende de M2+M3)*

**Meta:** catálogo navegável + telas de gestão.

**DoD:** catálogo navegável; abrir versão antiga mostra spec estável; busca por slug/status funciona.

| Tarefa | Descrição |
|---|---|
| T4.1 | Listar/buscar widgets (slug/status) |
| T4.2 | Histórico de versões + depreciar |
| T4.3 | Telas de gestão de usuários/papéis/rotas |
| T4.4 | Integração ponta a ponta + revisão final |

---

## Log de progresso

> Atualizado ao fim de cada tarefa/fase. Cada entrada: o que foi feito, decisões e o resultado da revisão (boas práticas).

### 2026-06-14
- **Planejamento**: roadmap (fases→tarefas) e plano detalhado do M0 criados. Toolchain verificada. Início do M0.
- **T0.1** ✅ Fundação do monorepo: `pnpm-workspace.yaml`, root `package.json`, `.gitignore`/`.nvmrc`/`.editorconfig`/`.env.example`, READMEs por diretório, `infra/docker-compose.yml` (Postgres+Redis).
- **T0.2** ✅ Esqueleto `@widgetmill/spec` (TS + Vitest + Zod 3.25). `pnpm install` OK.
- **T0.3** ✅ `Bindable` + `Color` (TDD, 9 testes). Binding/token centralizados num só helper (DRY).
- **T0.4** ✅ `EdgeInsets` + `TextStyle` (TDD, 9 testes). Gotcha do `.strict()` coberta por teste (preserva lados em `{left,top}`).
- **T0.5** ✅ Nós do núcleo (Text/Column/Container) + `Node` (união discriminada recursiva). Ciclo de import quebrado via holder `node-ref` (lazy). 5 testes.
- **T0.6** ✅ 🎯 **Checkpoint vertical**: 3 fixtures golden (`fixtures/nodes/*.json`) validados pelo Zod. **Suíte: 28 testes verdes.** Contrato dos 3 primitivos travado para o renderer Dart (M1) consumir.
- **T0.7** ✅ Complexos restantes (`BorderRadius`, `Alignment`/`AlignmentDirectional`, `BoxConstraints`, `BoxDecoration` com border/boxShadow/gradient). Cor com binding (`{{bg}}`) no decoration. 24 testes.
- **T0.8** ✅ 14 primitivos + `Positioned`. `flexProps` compartilhado (Row/Column, DRY). Container enriquecido com a regra do Flutter `color ⊥ decoration` (refine). 70 testes.
- **T0.9** ✅ `Action` (união por type) + `Events` + `GestureDetector`; `onPressed` ligado ao Button. Exemplo da spec §4 validado.
- **T0.10** ✅ `WidgetSpec` de topo (`specVersion`/`propsSchema`/`tree`) + `PropDef`; fixture `primary_button` (spec §6) valida ponta a ponta. `index.ts` expõe a superfície pública. **76 testes.**
- **T0.11** ✅ **Revisão M0** (ver abaixo). `@types/node` adicionado; `tsc --noEmit` limpo; `pnpm -r test` verde.

### Revisão da fase M0 (boas práticas)

> **DoD do M0 atingido**: `pnpm test` valida todos os fixtures (nodes + widget) e specs inválidos são rejeitados com erro legível (`safeParse` → `issues`).

- **Responsabilidade única / arquivos pequenos**: 1 schema por arquivo — 31 arquivos de produção, ~656 LOC (≈21 LOC/arquivo).
- **DRY**: binding/token num único `Bindable`; `Color`/`BindableColor`/`BindableNumber`/`BindableString` centralizados em `scalars.ts`; `flexProps` reutilizado por Row/Column; `NodeRef` é o único ponto de recursão.
- **KISS**: schemas declarativos diretos; sem codegen nem abstrações prematuras.
- **Fronteiras / modularização**: `packages/spec` sem dependências internas; camadas `bindable → scalars → complex → actions → nodes → tree → schema`, sem ciclos (exceto o `node-ref`, controlado e documentado para resolver a recursão).
- **YAGNI**: field descriptors (Inspector) e tradutor Puck adiados para o M2; tokens do design system fora do M0.
- **Correção (fidelidade ao Flutter)**: `color ⊥ decoration` (refine), `.strict()` no `EdgeInsets` (preserva os lados), enums serializados por nome.
- **TDD**: cada unidade teve teste vermelho antes do verde (76 testes).
- **Decisão deliberada**: `props` dos nós são permissivas (não-`strict`), enquanto os value-objects complexos são `strict`. Razão: props evoluem e o Inspector gera props válidas; value-objects são fechados. A revisar se aparecer footgun de digitação em specs escritos à mão.

**Próximo:** M1 (renderer Flutter `sdui_flutter` + preview), consumindo `packages/spec/fixtures` nos testes golden.

### 2026-06-15 — M1 (Renderer & Preview)

- **T1.0** ✅ Toolchain Flutter de-riscada (Flutter 3.38.6 via puro; `pub get`/`test` verdes).
- **T1.1** ✅ `SduiNode` + parsers (color/edgeInsets/textStyle) + conversores de enum (TDD, 13 testes).
- **T1.2/T1.3** ✅ Engine (`SduiRenderer`/`SduiRegistry`) + builders Container/Column/Text — **WS-0**.
- **T1.4** ✅ 🎯 **WS-0 completo**: teste golden renderiza os mesmos `packages/spec/fixtures/nodes` que o Zod valida (paridade Zod↔Dart travada).
- **T1.5** ✅ Builders dos 11 restantes + `Positioned` + Container enriquecido (decoration/alignment/constraints) + catálogo curado de ícones. Fixture `rich-showcase` valida nos dois lados.
- **T1.6** ✅ Resolução de binding `{{...}}`/token `$...` (passe puro) + integração: `primary_button` (M0) renderiza pelo M1 com bindings (TDD).
- **T1.7** ✅ Dispatcher de ações: `gestureDetector` (onTap/onLongPress/onDoubleTap) e Button `onPressed` (TDD).
- **T1.8** ✅ **WS-1**: `sdui_preview` (Flutter Web) + bridge `postMessage` com validação de `origin`. Lógica de mensagens testada (5 testes); `flutter analyze` limpo; `flutter build web` ✓.
- **T1.9** ✅ **WS-2**: `apps/web` (Next 15/React 19) — textarea + iframe + molduras de dispositivo; valida o JSON com o **próprio kernel** antes do `postMessage`. `tsc` + `next build` ✓. Preview servido na mesma origem (`public/preview`).

### Revisão da fase M1 (boas práticas)

> **DoD do M1**: WS-0/WS-1 **verificados** (golden parity + compilação web); WS-2 verificado em build/typecheck. A interação visual ao vivo (digitar JSON → preview muda) é executável via `pnpm --filter @widgetmill/web dev` + `flutter`/asset servido, mas não foi exercida em navegador neste ambiente (sem browser) — verificação manual pendente.

- **Responsabilidade única / arquivos pequenos**: 1 builder por primitivo (16); parsing dividido por preocupação (color/edge/style, enums, decoration); engine coeso num arquivo; bridge separada da lógica de mensagens.
- **DRY**: parsers/enums centralizados; binding como **um** passe puro (não repetido por builder); `registry` é a única fonte `type→builder`; sem duplicar regras de cor.
- **KISS / YAGNI**: renderer lê o mapa JSON direto (sem `freezed`/codegen — decisão §6.2); subconjunto curado de ícones (§6.4); nada de design system/tokens além do gancho.
- **Modularização / fronteiras**: `sdui_flutter` é renderer puro (sem deps internas); `sdui_preview → sdui_flutter`; `apps/web` consome `@widgetmill/spec` (validação no editor) e nunca o contrário.
- **Anti-drift (parceria com o M0)**: o teste golden renderiza os fixtures canônicos; qualquer divergência Zod↔Dart quebra um dos lados. 4 fixtures, incluindo um rico com muitos primitivos.
- **TDD**: cada unidade teve teste vermelho antes do verde (43 testes Dart no total).
- **Decisões registradas**: sem codegen (§6.2); ícones curados (§6.4); preview na mesma origem com `origin` validável na bridge (§6.3).

**Total da stack até aqui: 119 testes verdes** (76 kernel + 38 renderer + 5 preview).

**Próximo:** M2 (Editor/Builder com Puck + Inspector gerado) — depende do M1; e M3 (backend NestJS/Prisma/RBAC) pode correr em paralelo a partir do M0. Ambos exigem mais infraestrutura (navegador para o editor; Postgres para o backend).

### 2026-06-15 — M2 (Editor/Builder) — núcleo + WS-3

- **T2.3** ✅ Tradutor **Puck↔spec** (`specToPuck`/`puckToSpec` + helpers de documento) em `packages/spec/src/puck` — sem depender de `@measured/puck` (tipos estruturais). **Round-trip idempotente** testado em 7 casos + **200 árvores geradas** (validadas no kernel). Mitiga o risco §14.
- **T2.4** ✅ **Field descriptors** (`descriptors/catalog.ts`) — 1 entrada por primitivo; teste **anti-drift** (todo primitivo precisa de descriptor) + regra `color ⊥ decoration`. **Kernel: 90 testes.**
- **T2.2+T2.5** ✅ (WS-3) Editor **Puck** em `apps/web` (`/`): config **gerada a partir dos descriptors** (DRY), Slots para aninhamento, Inspector gerado, placeholders no canvas + **preview Flutter ao vivo** (mesma bridge do M1). Estado inicial vem do próprio tradutor (`specToPuckData`). `next build` ✓.
- **T2.7** ✅ Layers (outline) + undo/redo: **recursos nativos do Puck** (não reimplementados — KISS/DRY).
- **T2.8** ✅ Preview embarcado com **debounce** (250 ms); página JSON (WS-2) movida para `/json` como fallback.

### Revisão da fase M2 (boas práticas)

> **DoD do M2 (parcial)**: WS-3 entregue e compilado; edição visual → preview funciona pela bridge já provada. A montagem completa do `primary_button` *com seletor visual de binding* depende do follow-up T2.6/binding-UI (bindings já são utilizáveis digitando `{{prop}}` nos campos). Verificação visual no navegador: pendente do usuário.

- **DRY**: a config do Puck e o estado inicial são **derivados** (descriptors + tradutor) — adicionar um primitivo continua sendo "schema + descriptor + builder", sem UI nova.
- **KISS / YAGNI**: aproveitados os recursos nativos do Puck (estado, histórico, palette, outline) em vez de Zustand+zundo+RHF — menos código, menos divergência. Decisão registrada (desvio consciente do stack listado no plano).
- **Fronteiras**: o tradutor mora no kernel e **não** importa Puck (tipos estruturais); `apps/web` depende de `@widgetmill/spec`. O kernel segue publicável isolado.
- **Anti-drift**: round-trip property-based (Puck↔spec) + descriptor obrigatório por primitivo (testes quebram se um primitivo for adicionado sem par).
- **Follow-ups conscientes**: editor de ações (T2.6), editores ricos de tipos complexos (edgeInsets 4 lados, color picker), e gestão de props públicas/binding-picker — todos pós-verificação visual.

**Total da stack: 133 testes verdes** (90 kernel TS + 43 Dart [38 renderer + 5 preview]) e builds/análises limpos (`tsc`, `next build`, `flutter build web`, `analyze`).

**Como testar o editor:** `pnpm --filter @widgetmill/web dev` → `/` (editor visual) e `/json` (fallback).

**Próximo:** verificação visual do editor; depois T2.6 (ações) ou **M3** (backend NestJS/Prisma/RBAC/workflow), que pode começar do M0 e roda com Postgres via `infra/docker-compose.yml`.

### 2026-06-15 — Revisão de qualidade (2ª rodada)

Verificado o estado pós-melhorias (enums centralizados, type guards no tradutor, `targetOrigin` na bridge): **kernel 90 + renderer 38 + preview 12 = 140 testes verdes**, `tsc`/`analyze`/`next build` limpos.

- ✅ **Centralização de enums** (`packages/spec/src/enums.ts`): single source of truth para schemas + descriptors — fecha a duplicação apontada na revisão do M2.
- ✅ **Type guards no tradutor** (`puck/translate.ts`): `isPuckComponent`/`asPuckComponentArray` no lugar de `as` — round-trip seguro.
- ✅ **Bridge `targetOrigin`** específico (least privilege) em vez de `'*'` fixo.
- 🔧 **Corrigido**: a lógica pura da bridge (`processIncoming`) estava no mesmo arquivo dos imports web → **não testável na VM e sem teste**. Movida para `lib/src/incoming.dart` (pura) + **7 testes** cobrindo allowlist/origin nulo/payload.
- 📌 **Recomendações** — **aplicadas**:
  - (a) ✅ `ALIGNMENT`/`ALIGNMENT_DIRECTIONAL`/`FONT_WEIGHT` centralizados em `enums.ts`, usados por `complex/alignment.ts`/`textStyle.ts`, exportados no `index` e consumidos em `apps/web/lib/puck-config.tsx` (sem mais hardcode cross-package).
  - (b) ✅ `allowedOrigins` configurável via `--dart-define=PREVIEW_ALLOWED_ORIGINS=...` (`parseAllowedOrigins` puro + testado); vazio = aberto só em dev. Em produção: `flutter build web --dart-define=PREVIEW_ALLOWED_ORIGINS=https://app.exemplo.com`.

Pós-aplicação: **kernel 90 + renderer 38 + preview 15 = 143 testes verdes**; `tsc`/`analyze`/`next build`/`flutter build web` limpos; asset do preview recompilado e recopiado.

### 2026-06-15 — Ponto de parada (M3 postergado)

A pedido do usuário, **M3 (backend) fica postergado** — há problemas a resolver antes (ver seção "⚠️ Pendências e problemas em aberto"). Estado **commitado** para retomar depois. M0/M1 completos; M2 com núcleo + editor (WS-3) entregues e verificados por build/teste; verificação visual do editor e follow-ups do M2 pendentes.

### 2026-06-15 — DX + polish do editor (retomada)

- **`.vscode/`**: `launch.json` (rodar/depurar o editor Next e o preview Flutter), `tasks.json` (build do preview → `public/preview`, dev server, testes) e `extensions.json`. `settings.json` (caminho do SDK puro) fica fora do git.
- **Paleta por categorias (colapsáveis)**: agrupamento dos primitivos vira fonte única no kernel — `COMPONENT_CATEGORIES` + `paletteCategories()` em `descriptors/categories.ts` (TDD, 5 testes). Categorias: **Layout · Flex & Posição · Conteúdo · Interação**, com fallback "Outros" anti-drift (primitivo sem categoria não some). `apps/web/lib/puck-config.tsx` consome via `categories` do Puck (`defaultExpanded: true`). Kernel: 90 → **95 testes**.

### 2026-06-15 — Salvar widget + versionamento estilo Squidex (plano `fizzy-bouncing-haven`)

Modelo **event-sourced fiel ao Squidex** (cada save = versão imutável; reverter = Carregar+Salvar não-destrutivo; "usada" = última publicada). Persistência **funcional em memória** atrás da interface `WidgetRepository` (o M3 só troca a implementação por `ApiWidgetRepository`).

- **Kernel (TDD, +23 testes → 118):** `identity/slug.ts` (`slugify`), `widget/factory.ts` (`makeWidgetSpec`), `history/{types,record}.ts` (registro append-only: `saveVersion`/`publishedVersion`/`latestVersion`/`getVersion`), `history/diff.ts` (`diffTree` — diff estrutural líquido; possível porque o conteúdo é árvore JSON, ao contrário do rich text que fez o Squidex postergar o diff). Tudo exportado em `src/index.ts`.
- **Seam (web):** `lib/widget-repo/` (`WidgetRepository` + `InMemoryWidgetRepository` + instância default trocável em 1 linha) e `lib/widget-session.tsx` (`useWidgetSession`; ações leem de refs p/ evitar closure velha no "criar identidade + salvar" no mesmo gesto).
- **UI:** `PreviewFrame` extraído (reusado no compare); header do Puck via `renderHeaderActions` com **Salvar** / **Salvar e Publicar** / **Histórico** + chip de status; `IdentityDialog` (nome + slug editável + descrição); `HistoryPanel` estilo Squidex (autor/mensagem/tempo relativo + **Carregar**·**Comparar**, badge "usada"); `CompareView` (dois previews lado a lado + `SpecDiff` colorido); `PreviewBanner` (aviso "em memória") + `Toast`. "Carregar" aplica via `dispatch({type:"setData"})`.
- **Verificação:** kernel **118 testes** verdes; `tsc` (kernel+web) limpo; `next build` 5/5. Verificação visual interativa (drag→salvar→publicar→carregar→comparar) pendente no navegador.

### 2026-06-15 — Ajustes pós-verificação visual (diff, excluir versão, validação de montagem)

Refinos a partir do uso real no navegador:

- **Cores do diff** (`SpecDiff`): verde=adicionado · vermelho=removido · **azul=modificado**.
- **Bug de raiz dupla** (causa do "diff não detectava"): `puckDataToSpec` descartava raízes além da primeira. Agora **múltiplas raízes são envolvidas num `column` implícito** (preserva conteúdo no preview/diff). TDD em `translate.test.ts`. Kernel 118 → 127.
- **Excluir versão do histórico** (estilo Squidex): `deleteVersion` no kernel é **soft-delete** (tombstone `deletedBy`/`deletedAt`; numeração monotônica nunca reusa; `latest`/`published` ignoram excluídas) — TDD. UI: link **Excluir** no `HistoryPanel` (linha vira tombstone "excluída por X · há Y"), `ConfirmDialog` que **avisa que a exclusão fica registrada** e não se desfaz. Propagado via `WidgetRepository.deleteVersion`.
- **Comparação com JSON**: `CompareView` ganhou toggle **Diff / JSON** (mostra o JSON completo das duas versões lado a lado).
- **Validação de montagens problemáticas** (novo): `diagnostics/diagnose.ts` no kernel (TDD, +10 → **137**) detecta **erros** (múltiplas raízes; `Expanded`/`Flexible`/`Spacer` fora de Row/Column; `Positioned` fora de Stack; slot de filho único com vários; `color`+`decoration` no Container) e **avisos** (layout/Text vazios), cada um apontando o `id` do nó. `nodes/slots.ts` virou fonte única do slot (filho único × vários), consumida pelo `puck-config` e pelo diagnose. UI: **barra de status** no rodapé (resumo + lista), **marcação no canvas** (contorno vermelho/âmbar via `DiagnosticsContext`), e **"Salvar e Publicar" bloqueado** enquanto houver erro (rascunho ainda salva).
- **Decisão de produto:** múltiplas raízes deixam de ser "consertadas em silêncio" — são sinalizadas como erro (o `column` implícito é só best-effort do preview).
- **Verificação:** kernel **137 testes**; `tsc` (kernel+web) limpo; `next build` 5/5.

### 2026-06-15 — Restaurar versão + correção da barra de status

- **Restaurar versão excluída:** `restoreVersion` no kernel desfaz o soft-delete (TDD, kernel → **139**); propagado em `WidgetRepository`/in-memory/`useWidgetSession`; link **Restaurar** no tombstone do `HistoryPanel`.
- **Barra de status não aparecia:** o layout do Puck usa `height: 100dvh`, ocupando a tela e empurrando a `StatusBar` para fora. Corrigido em `apps/web/app/editor.css` (`.wm-editor-host` flex-column; root do Puck `flex:1`; layout interno `height:100%`). A marcação no canvas (contorno vermelho/âmbar) já funcionava.
- **Verificação:** kernel **139 testes**; `tsc` (kernel+web) limpo; `next build` 5/5.

### 2026-06-17 — Editores de propriedade padronizados, dimensões relativas e catálogo de widgets

Branch `feature/property-editors-and-widget-catalog` (de `develop`). Plano: [docs/superpowers/plans/2026-06-17-property-editors-and-widget-catalog.md](superpowers/plans/2026-06-17-property-editors-and-widget-catalog.md). **Não mergeado na `develop`** — aguarda revisão visual.

- **Dimensão relativa (headline):** novo tipo `complex/dimension.ts` (`Dimension`/`BindableDimension`) — px fixo **OU** token relativo `{unit:"infinity"}`, `{unit:"screenWidth|screenHeight", factor}` (multiplicador). Aplicado a `width/height` de container/sizedBox/image. Renderer: `resolveDimension(context, v)` resolve para `double` (incl. `double.infinity` e `MediaQuery.sizeOf(c)*factor`). Editor: **DimensionField** com modos *Fixo / Preencher / % Larg. / % Alt.*. "% do pai" coberto pelo novo `fractionallySizedBox`.
- **Editores reutilizáveis (web, `inspector-fields.tsx`):** `DimensionField`, `ShadowListField` (lista de `boxShadow`: cor+offset+blur+spread), `GradientField` (linear/radial + cores + begin/end), `MiniSelect`, e **cabeçalhos de seção** (`sectionHeaderField`) — o Inspector agora agrupa campos por `group` em seções (estilo FlutterFlow). Novos `FieldType`: `dimension`, `borderRadius`, `buttonStyle`. `boxDecoration` passou a expor **sombras + gradiente**; `button.style` (antes só no schema) agora é editável.
- **Propriedades enriquecidas:** `button.style` ganhou `elevation`/`borderRadius`/`side`/`textStyle` + prop `icon` (variantes `*.icon(...)`). Obrigatórias (`*`) em `aspectRatio.aspectRatio` e `opacity.opacity`.
- **9 widgets novos do catálogo Flutter:** `wrap`, `card`, `divider`, `align`, `aspectRatio`, `fractionallySizedBox`, `opacity`, `safeArea`, `singleChildScrollView` (schema + descriptor + categoria + builder + slots). Nova categoria de paleta "Dimensão & Efeitos".
- **Fix achado nos testes:** `singleChildScrollView` defaultava para scroll horizontal (default genérico de `axisFrom`); corrigido para **vertical** (default do Flutter).
- **Verificação:** kernel **170 testes** (+ `dimension.test.ts`, descriptors, fixture `relative-and-catalog`); renderer **40 testes Dart** (+ `resolveDimension` + golden do fixture novo); `tsc` (kernel+web) limpo; `next build` 0 erros; `flutter analyze` limpo; asset do preview recompilado. **Verificação visual interativa do Inspector (seções, DimensionField, sombras) pendente no navegador.**

#### Correção (mesmo dia) — spec "limpa": props ausentes quando não informadas
Plano: [docs/.../calm-questing-wigderson] (decisões: bool tri-estado · salvar árvore crua · hints de default = follow-up).
- **Causa-raiz:** `makeWidgetSpec` retornava `WidgetSpec.safeParse().data` (parseado, com defaults preenchidos) e o `saveVersion` guardava isso → **salvar** injetava `enabled:true`/`size:24`/`spacing:0`/etc. na versão salva (reapareciam ao Carregar/Comparar). Além disso, 14 `.default(valor)` por-prop nos schemas materializavam em qualquer `Node.parse`. (A edição ao vivo via `puckDataToSpec` já era limpa.)
- **Botão arredondado:** é o default do **Material 3** do Flutter (`StadiumBorder`/pílula), não definido no nosso código — comportamento desejado (ausência → default do framework); só sobrescrito quando há `style.borderRadius`.
- **Fix:** 14 `.default(valor)` por-prop → `.optional()` (mantidos os estruturais `{}`/`[]`); o renderer já aplica o mesmo fallback na ausência. `makeWidgetSpec` agora valida o envelope mas **persiste a árvore crua** (`tree: input.tree`), igual à montagem do editor. Editor: bool opcional vira **tri-estado** ("— / sim / não"; "—" = ausente). Testes (`nodes.test.ts`/`tree.test.ts`) passam a afirmar **ausência**.
- **Verificação:** kernel **170 testes** · `tsc` (kernel+web) limpo · `next build` 0 erros · `flutter analyze`+**40 testes** verdes. (Sem mudança no Dart → asset do preview inalterado.) Replicado a todos os componentes (mudança centralizada). Verificação visual no navegador pendente.

#### Correção (mesmo dia) — seletor de modo "mentia" (valor não acompanhava a aba)
Plano: [docs/.../calm-questing-wigderson]. Bug: definir `height = Preencher` e depois trocar para `Fixo` deixava a aba em "Fixo" mas o valor seguia `{unit:"infinity"}` (preview continuava preenchendo). Atingia os 3 campos com modo.
- **Causa-raiz:** três fontes de verdade dessincronizando — store do Puck; `AutoFieldPrivate.localValue` (buffer por campo, re-sincronizado com o store **só quando o campo não está focado** — `@measured/puck` dist ~4414-4441); e o **estado `mode` local** dos nossos campos. O `mode` local permitia a aba exibir um modo divergente do valor salvo.
- **Fix:** o **`value` virou a única fonte de verdade do modo**. `DimensionField`/`EdgeInsetsField`/`BorderRadiusField` derivam o modo do valor (sem `useState`+`useEffect` de modo; mantido um modo local só para o caso vazio/ambíguo em edge/radius). Toda troca de modo grava um valor completo num único `onChange` (% entra com fator 1 = 100%; esvaziar o % mantém o modo; só a aba "Fixo" limpa).
- **Verificação:** `tsc` (web) limpo · `next build` 0 erros. (Sem mudança no kernel/Flutter.) Verificação visual no navegador pendente.

#### Ajustes (mesmo dia) — defaults visíveis + layout fluído
- **Defaults visíveis (#2):** novo campo `default` no `FieldDescriptor`; `puck-config` monta `defaultProps` por primitivo a partir deles, então ao **adicionar** um componente os padrões do Flutter (variant=elevated, enabled=true, mainAxisAlignment=start, fit=contain, size=24, flex=1, etc.) já aparecem **pré-preenchidos** no Inspector e na aba Spec — o usuário vê o que está configurado. Defaults são uma camada do **editor** (Puck), não do schema (Zod segue `.optional()`); a omissão é higienização opcional no export pro Dart (o renderer já aplica o mesmo default na ausência).
- **Layout fluído + scroll (#1/#3):** `editor.css` — cadeia de altura robustecida (`.wm-editor-host > *` preenche; raiz `_Puck_` + `PuckLayout` em `height:100%`) para os painéis (montagem/Spec) ocuparem a altura disponível em vez de colapsar para o conteúdo. Cada painel mantém a própria rolagem (canvas via `_PuckCanvas` overflow:auto; Spec via `JsonView`). **Verificação visual no navegador pendente.**
- `tsc` (kernel+web) limpo · `next build` 0 erros · kernel 170 testes.
