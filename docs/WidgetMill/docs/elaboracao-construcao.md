# WidgetMill — Elaboração da Construção

> Este documento traduz o [plano](plano-construtor-de-widgets.md) e a [spec v1](spec-json-v1.md) em um **roteiro executável**: estrutura de repositório, o contrato compartilhado como núcleo, a fatia vertical que de-risca a arquitetura cedo, e milestones com critérios de aceite. Nada aqui contradiz os dois documentos-base; este aprofunda *como construir*.

---

## 0. Princípio organizador: o spec é o kernel

Tudo no produto radia de um único artefato — o **spec JSON** — e de uma única fonte de verdade que o descreve. A regra de ouro:

> **Há um e apenas um lugar onde a forma do spec é definida. Todo o resto é derivado dele.**

```
                       ┌─────────────────────────────┐
                       │  packages/spec  (Zod kernel) │  ◀── fonte de verdade
                       │  schema · tipos · descriptors │
                       └──────────────┬───────────────┘
                derivado              │              derivado
        ┌──────────────────┬─────────┼─────────┬──────────────────┐
        ▼                  ▼          ▼         ▼                  ▼
  Inspector forms     Validação    Tradutor   Tipos TS       Fixtures golden
  (web, gerados)      (FE + BE)    Puck↔spec  (FE + BE)      (contrato p/ Dart)
                                                                   │
                                                                   ▼
                                                          flutter/sdui_flutter
                                                          (freezed + registry)
```

Consequência prática: **congelar o spec v1 é a primeira tarefa de código** (Fase 1 do plano), porque é o item de maior risco (§14 do plano — "spec instável → migração custosa"). Tudo o mais depende dele.

---

## 1. Estrutura do repositório (monorepo)

Monorepo híbrido: workspace **pnpm** para o lado TypeScript, workspace **pub** para o lado Flutter, lado a lado.

```
widgetmill/
├─ apps/
│  ├─ web/                  # Next.js (App Router, TS) — editor + telas de gestão
│  └─ api/                  # NestJS (TS) — RBAC, workflow, versionamento, catálogo
├─ packages/
│  └─ spec/                 # @widgetmill/spec — KERNEL
│     ├─ src/
│     │  ├─ nodes/          # schema Zod por primitivo (container, text, column, ...)
│     │  ├─ complex/        # edgeInsets, textStyle, boxDecoration, alignment...
│     │  ├─ actions/        # eventos + lista de ações (navigate, openUrl, ...)
│     │  ├─ descriptors/    # field descriptors → geram os forms do Inspector
│     │  ├─ puck/           # tradutor Puck ↔ spec (isolado, round-trip testado)
│     │  ├─ schema.ts       # union discriminada de nós + spec de topo (specVersion)
│     │  └─ index.ts
│     └─ fixtures/          # specs canônicos (.json) — contrato compartilhado com o Dart
├─ flutter/
│  ├─ sdui_flutter/         # package: renderer real (freezed models + registry type→builder + dispatcher de ações)
│  │  └─ test/golden/       # consome packages/spec/fixtures → garante paridade com o Zod
│  └─ sdui_preview/         # app Flutter Web mínimo: embarca sdui_flutter + bridge postMessage
├─ infra/
│  ├─ docker-compose.yml    # Postgres + Redis (dev)
│  └─ prisma/
│     ├─ schema.prisma      # modelo de dados (§10 do plano)
│     ├─ migrations/
│     └─ seed.ts            # provisiona 1 projeto + primitivos + roles + workflow padrão
├─ pnpm-workspace.yaml
├─ turbo.json               # orquestração de tasks (build/test/lint) — opcional mas recomendado
└─ package.json
```

### Decisões de tooling (recomendadas, reversíveis)

| Item | Escolha | Por quê |
|---|---|---|
| Gerenciador de pacotes | **pnpm** + workspaces | rápido, workspaces nativos, bom com Turborepo |
| Orquestrador de tasks | **Turborepo** | cache de build/test entre `apps/*` e `packages/*` |
| Node | **20 LTS** | requisito de Next 14+/NestJS 10+ |
| Flutter | **stable ≥ 3.27** | a spec assume `spacing` em Row/Column (GA no 3.27) |
| Auth | **Better-Auth** (backend-owned) | backend é NestJS separado; sessão/JWT controlada pela API, não pelo Next. Auth.js é Next-cêntrico demais para este desenho |
| Onde o preview é servido | build de `sdui_preview` → `apps/web/public/preview/` | **mesma origem** do Next ⇒ validação de `origin` no `postMessage` é trivial e segura |

### 1.1 Convenções de organização

A aplicação é construída **nesta pasta**, e a disciplina de "cada coisa no seu diretório" é uma regra do projeto:

- **kebab-case** para diretórios; pacotes TS sob o escopo **`@widgetmill/*`**.
- Cada `app`/`package` é **autocontido**: tem o próprio `package.json`, `tsconfig.json`, testes e `README.md`. Nada "solto" na raiz além de configuração compartilhada.
- Cada diretório de primeiro nível ganha um **`README.md` curto** (o que vive ali — auto-documentação); diretórios ainda sem código são versionados com **`.gitkeep`**.
- **`docs/`** permanece na raiz (este planejamento + a spec).
- **Raiz só com configuração compartilhada**: `pnpm-workspace.yaml`, `turbo.json`, `package.json`, `.nvmrc`, `.editorconfig`, `.gitignore`, `.env.example`, `README.md`.
- **Duas toolchains, dois mundos**: o lado Flutter fica isolado em `flutter/` (workspace pub), separado do workspace pnpm. Não se misturam.

### 1.2 Fronteiras de dependência (quem importa quem)

A direção das dependências é regra, não acaso — é o que impede o monorepo de virar um emaranhado:

```
apps/web ─┐
          ├─▶ packages/spec ──▶ (só libs externas: zod)
apps/api ─┘
flutter/sdui_preview ──▶ flutter/sdui_flutter ──▶ (nada interno)
```

- **`packages/spec` é o núcleo e não depende de nada interno** — poderia ser publicado/reusado isolado.
- **`apps/*` dependem de `packages/spec`, nunca o contrário**; `apps/web` e `apps/api` **não se importam** entre si (conversam por HTTP).
- **`sdui_flutter` é renderer puro**; só toca `packages/spec/fixtures` em testes (golden).
- Enforçado por **TS project references + regra de import no ESLint + grafo do Turborepo** — uma violação de fronteira quebra o build, não passa em review por sorte.

---

## 2. O contrato compartilhado (kernel) em detalhe

### 2.1 Zod como fonte de verdade

Cada primitivo da [spec v1 §2](spec-json-v1.md) vira um schema Zod. Padrão (união discriminada por `type`):

```ts
// packages/spec/src/complex/edgeInsets.ts
export const EdgeInsets = z.union([
  z.object({ all: z.number() }),
  z.object({ horizontal: z.number().optional(), vertical: z.number().optional() }),
  z.object({ left: z.number().optional(), top: z.number().optional(),
            right: z.number().optional(), bottom: z.number().optional() }),
]);

// packages/spec/src/nodes/text.ts
export const TextNode = z.object({
  type: z.literal("text"),
  props: z.object({
    data:      Bindable(z.string()).default(""),
    style:     TextStyle.optional(),
    textAlign: z.enum(["left","right","center","justify","start","end"]).default("start"),
    maxLines:  z.number().int().optional(),
    overflow:  z.enum(["clip","fade","ellipsis","visible"]).default("clip"),
    softWrap:  z.boolean().default(true),
  }),
  events: Events.optional(),
});

// packages/spec/src/schema.ts
export const Node = z.discriminatedUnion("type", [
  ContainerNode, ColumnNode, RowNode, StackNode, TextNode, ImageNode,
  IconNode, ButtonNode, SizedBoxNode, PaddingNode, CenterNode,
  ExpandedNode, SpacerNode, GestureDetectorNode,
]);

export const WidgetSpec = z.object({
  specVersion: z.literal(1),              // migração futura sem quebrar widgets salvos
  slug: z.string(), name: z.string(),
  kind: z.enum(["primitive","composite"]),
  propsSchema: z.array(PropDef),
  tree: Node,
});
```

**Binding `{{prop}}`**: o helper `Bindable(inner)` aceita ou o valor tipado, ou a string `"{{chave}}"`, ou um token `"$nome"` (design system, [spec §5](spec-json-v1.md)). Assim binding é uniforme e validado em um só lugar.

```ts
const BINDING = /^\{\{\s*[\w.]+\s*\}\}$/;
const TOKEN   = /^\$[\w.]+$/;
const Bindable = <T extends z.ZodTypeAny>(inner: T) =>
  z.union([inner, z.string().regex(BINDING), z.string().regex(TOKEN)]);
```

Tipos TS para FE e BE saem grátis: `type WidgetSpec = z.infer<typeof WidgetSpec>`.

### 2.2 Field descriptors → forms do Inspector gerados

Em vez de codar um form por primitivo, as tabelas da [spec §2](spec-json-v1.md) viram **dados**. O Inspector renderiza campos genéricos por `type`.

```ts
// packages/spec/src/descriptors/container.ts
export const containerFields: FieldDescriptor[] = [
  { key: "width",   type: "double",     group: "Layout" },
  { key: "height",  type: "double",     group: "Layout" },
  { key: "padding", type: "edgeInsets", group: "Spacing" },
  { key: "color",   type: "color",      group: "Style",
    hidden: (props) => !!props.decoration?.color },   // regra Flutter: color ⊥ decoration
  { key: "alignment", type: "enum", enumValues: ALIGNMENTS, group: "Layout" },
];
```

O Inspector mapeia `type → componente de campo` (string→input, color→react-colorful, enum→select, edgeInsets→editor de 4 lados, actionList→editor de eventos). **Adicionar um primitivo = adicionar uma entrada de schema + uma de descriptor**, zero UI nova.

### 2.3 Tradutor Puck ↔ spec (ponto de atrito — isolar e testar)

Puck tem seu próprio modelo (instâncias de componente com props + slots). O tradutor mora em `packages/spec/src/puck/` e é **bidirecional e idempotente**:

```ts
specToPuck(spec) → PuckData
puckToSpec(data) → WidgetSpec
// invariante testada: puckToSpec(specToPuck(s)) deep-equals s
```

Mapeamento: cada componente Puck ↔ um `type` de nó; props 1:1; **slots Puck → `child` / `children`**. Property-based tests com specs gerados aleatoriamente garantem o round-trip (mitiga o risco §14 do plano).

### 2.4 Paridade Dart sem pipeline de codegen (v1)

A spec Dart (`freezed` + `json_serializable`) é **escrita à mão espelhando o Zod** — são poucos primitivos. A garantia contra drift não é codegen, é **fixtures golden compartilhados**:

```
packages/spec/fixtures/*.json   ← um conjunto de specs canônicos
   ├─ validado pelo Zod          (teste em packages/spec)
   └─ parseado+reserializado     (teste golden em flutter/sdui_flutter)
```

Se Zod e Dart divergirem, um dos dois testes quebra. Pipeline de codegen (Zod→JSON Schema→Dart) fica como evolução, só se o drift doer.

---

## 3. Fatia vertical (walking skeleton) — de-riscar antes de escalar

O maior risco de integração não é nenhum primitivo isolado: é a **ponte React↔Flutter** e o **tradutor Puck↔spec**. Então a fatia vertical atravessa todas as costuras com o mínimo de primitivos (**Container, Column, Text** — só esses 3).

| Passo | Entrega | Valida | Sem ainda |
|---|---|---|---|
| **WS-0** | `sdui_flutter` renderiza um spec *hardcoded* (Container>Column>Text) | freezed models + registry `type→builder` | bridge, web |
| **WS-1** | `sdui_preview` (Flutter Web) escuta `postMessage`, re-renderiza | a bridge pelo lado Flutter | Puck, backend |
| **WS-2** | Página Next mínima: `<iframe>` + `<textarea>` de JSON → `postMessage` | **fidelidade ponta a ponta** editando JSON na mão + moldura de dispositivo | Puck, backend |
| **WS-3** | Troca o textarea por **Puck** (palette de 3) + tradutor `puckToSpec` | edição visual atualiza o preview (com debounce) | backend |
| **WS-4** | NestJS com 1 endpoint: salvar draft / publicar versão (projeto seedado, **sem RBAC**) | persistência + recarregar draft | RBAC, workflow |

Ao fim do WS-4 toda a arquitetura está provada ponta a ponta. Só então se escala em largura (resto dos primitivos) e em profundidade (RBAC, workflow, catálogo).

---

## 4. Milestones (refinamento das 10 fases do plano)

As 10 fases do [plano §12](plano-construtor-de-widgets.md) reagrupadas em milestones com **critério de aceite (DoD)** e dependências.

### M0 — Kernel & fundação  *(plano: fase 1)*
- `packages/spec`: schema Zod dos 14 primitivos + tipos complexos + eventos/ações + `specVersion`.
- `fixtures/` golden + testes Zod.
- Monorepo, pnpm/turbo, lint/format, `docker-compose` (Postgres+Redis).
- **DoD**: `pnpm test` valida todos os fixtures; um spec inválido é rejeitado com erro legível.

### M1 — Renderer & preview  *(fases 2–3 · depende de M0)*
- `sdui_flutter`: builders dos 14 primitivos + dispatcher de ações (registry estilo Stac) + testes golden contra `fixtures/`.
- `sdui_preview`: app Web, bridge `postMessage` com validação de `origin`, devolve eventos (altura, tap, erro) ao editor.
- **DoD**: WS-0..WS-2 verdes; editar o JSON na página muda o preview com fidelidade; dispositivos (iPhone/Android/tablet) trocam o tamanho.

### M2 — Editor (Builder)  *(fases 4–7 · depende de M1)*
- Palette (Puck) dos 14 primitivos; canvas com aninhamento (Slots); Layers sincronizada (Zustand+Immer+zundo, undo/redo).
- Tradutor Puck↔spec com round-trip testado.
- Inspector gerado por field descriptors (RHF+Zod) + **editor de eventos/ações** (lista ordenada).
- Definição de props públicas + binding `{{...}}`; preview embarcado com debounce.
- **DoD**: WS-3 verde; montar o `primary_button` ([spec §6](spec-json-v1.md)) inteiro no editor, com binding, e ver no preview.

### M3 — Backend: identidade, RBAC, workflow, versionamento  *(fases 8–9 · depende de M0; integra com M2)*
- NestJS + Prisma (modelo do [plano §10](plano-construtor-de-widgets.md)); Better-Auth.
- **Casbin**: 5 papéis → permissões em notação de ponto, escopadas por `project_id` (modelo `{app}` do Squidex).
- Multi-tenancy: todo acesso filtrado por `project_id`; primitivos em leitura para todos.
- Draft (lock otimista via `base_version`/`updated_at`) → workflow (state machine DB-driven, `workflow_transitions` seedado) → publicar incrementa versão (linha imutável em `widget_versions`).
- `project_routes` (CRUD) para alimentar a ação `navigate` (dropdown no Inspector).
- Audit log.
- **DoD**: WS-4 + fluxo `draft→in_review→approved→published` com papéis distintos; tentativa fora do papel é negada; publicar gera `version = current+1` imutável.

### M4 — Catálogo & polimento  *(fase 10 · depende de M2+M3)*
- Listar/buscar widgets, ver histórico de versões, depreciar.
- Telas de gestão de usuários/papéis/rotas.
- **DoD**: catálogo navegável; abrir uma versão antiga mostra spec estável; busca por slug/status funciona.

```
M0 ─┬─▶ M1 ─▶ M2 ─┐
    └─────────────┴─▶ (integração) ─▶ M4
        M3 ─────────┘
```
M3 pode correr em paralelo a M1/M2 após M0 (depende só do kernel + modelo de dados).

---

## 5. Provisionamento (bootstrap multi-tenant)

O [plano §8.0/§13](plano-construtor-de-widgets.md) define provisionamento **manual pelo super-admin** no MVP. Concretizado no `prisma/seed.ts`:

1. Cria a plataforma e os **primitivos** (nível plataforma, leitura para todos).
2. Cria **1 projeto** (a "licença") + Admin inicial.
3. Semeia os **5 papéis** com suas permissões em notação de ponto.
4. Semeia as **transições de workflow** padrão (as setas do [plano §8.3](plano-construtor-de-widgets.md)).
5. (Opcional) algumas `project_routes` de exemplo para testar `navigate`.

Provisionar nova licença = rodar uma rotina de seed parametrizada por projeto (super-admin). Self-service fica para depois, sem bloquear nada.

---

## 6. Decisões de implementação a fechar antes de codar

Itens de implementação (não estruturais — os estruturais já estão resolvidos no plano §13). Recomendação default entre colchetes; todas reversíveis.

1. **Auth**: Better-Auth (backend-owned) **[recomendado]** vs Auth.js no Next.
2. **Sync Zod↔Dart**: fixtures golden manuais **[recomendado p/ v1]** vs codegen Zod→JSON Schema→Dart.
3. **Hospedagem do preview**: asset estático em `apps/web/public/preview` (mesma origem) **[recomendado]** vs servido pela API (cross-origin).
4. **Catálogo de ícones (primitivo Icon)**: subconjunto curado de Material Icons **[recomendado]** vs catálogo completo.
5. **Orquestrador**: Turborepo **[recomendado]** vs scripts pnpm puros.

Nenhum desses bloqueia M0 (o kernel independe de todos). Podem ser fechados ao chegar na milestone que os toca.

---

## 7. Riscos — mitigação concreta (estende plano §14)

| Risco | Mitigação nesta elaboração |
|---|---|
| **Spec instável** | `specVersion` desde o v1; kernel único em `packages/spec`; fixtures golden travam o contrato; mudança no spec quebra teste em FE, BE e Dart simultaneamente |
| **Tradução Puck↔spec** | módulo isolado + property-based test de round-trip idempotente (M2 DoD) |
| **Preview Flutter Web** | app de preview enxuto; build como asset estático cacheável; bridge validada já no WS-1/WS-2, antes de qualquer complexidade |
| **Drift Zod↔Dart** | fixtures golden compartilhados (§2.4) — divergência = teste vermelho |
| **Escopo RBAC/workflow** | 5 papéis fixos + transições seedadas no banco; condições nas transições ficam pós-MVP (plano §13.13) |

---

## 8. Primeiros passos executáveis (ordem)

1. Inicializar monorepo (`pnpm-workspace.yaml`, `turbo.json`, `docker-compose` Postgres+Redis).
2. **M0**: criar `packages/spec` com Container/Column/Text + complexos que eles usam (EdgeInsets, TextStyle) + 3 fixtures golden + testes. *(começo da fatia vertical e do kernel ao mesmo tempo)*
3. **WS-0**: `flutter/sdui_flutter` renderizando esses 3 primitivos a partir de um fixture.
4. **WS-1/WS-2**: `sdui_preview` + página Next com iframe + textarea.
5. Seguir M1→M2→(M3 em paralelo)→M4 conforme §4.

> A regra ao longo de tudo: **cada novo primitivo é uma entrada no schema + uma no descriptor + um builder no renderer + um fixture golden.** Mecânico e incremental, como manda a [spec §7](spec-json-v1.md).
</content>
</invoke>
