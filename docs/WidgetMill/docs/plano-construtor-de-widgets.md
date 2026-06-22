# WidgetMill — Plano do Construtor de Widgets (Web)

> Documento vivo. Foco desta fase: o **Widget Builder** — editor visual que constrói widgets primitivos e os salva, versionados, em um **Catálogo** para reúso. Inspiração de UX: FlutterFlow. Inspiração de governança (papéis/fluxo): Squidex.
>
> 📐 **Como construir** (estrutura do repositório, convenções de organização, fronteiras de dependência, fatia vertical e milestones com critério de aceite): ver [elaboracao-construcao.md](elaboracao-construcao.md). A aplicação é construída **nesta pasta**, em monorepo organizado (`apps/`, `packages/spec`, `flutter/`, `infra/`, `docs/`).

---

## 1. Objetivo desta fase

Construir o **Widget Builder**: editor visual onde se compõe um widget a partir de **primitivos** (port dos widgets primários do Flutter), configura suas propriedades e ações, e **salva como artefato versionado no Catálogo**.

O produto do Builder é um **spec JSON** (dado, não código Dart), consumido depois por:
- outras partes da ferramenta web (editor de conteúdo);
- o renderer Flutter proprietário, no app do cliente final.

### Decisões desta fase (confirmadas)
- **Só primitivos.** Compostos nomeados (`productCard`) vêm depois, reusando primitivos. Nenhum composto é necessário agora.
- **Primitivos espelham os widgets do Flutter** — props derivadas da documentação oficial do Flutter.
- **Multiusuário** com papéis hierárquicos e permissões.
- **Edição via draft**: alterações ficam em rascunho até serem publicadas; publicar **incrementa a versão** do widget.
- **Preview fiel ao Flutter**, via Flutter Web embarcado, com simulação de dispositivos.
- **Responsivo**, com teste em múltiplos tamanhos de tela.
- **Aprovação hierárquica** no fluxo de publicação.
- **Multi-tenant**: a plataforma provisiona **um Projeto por licença**. Primitivos são da plataforma (compartilhados em leitura); widgets criados pelo cliente ficam isolados no projeto. Tudo escopado por `project_id`.

### Fora do escopo desta fase
Editor de conteúdo/montagem de páginas, regras de visibilidade (datas/segmentação), ambientes HML/Prod de *entrega*, o package renderer Flutter de produção e o backend de `GET /feeds`. (O renderer é reusado aqui apenas para o preview.)

---

## 2. Conceitos centrais

| Conceito | Definição |
|---|---|
| **Projeto (Tenant)** | Espaço isolado de um cliente licenciado. A plataforma cria um por licença. Contém os widgets, usuários, papéis e rotas daquele cliente. |
| **Primitivo** | **Foco atual. Nível plataforma**, compartilhado em leitura com todos os projetos. Port de um widget primário do Flutter (Container, Row, Column, Stack, Text, Image, Icon, Button, SizedBox, Padding, Center, Expanded, Spacer, GestureDetector). Props espelham o widget Flutter equivalente. O cliente **não cria** primitivos — apenas compõe a partir deles. |
| **Composto** | *(fase posterior)* Widget nomeado criado pelo cliente a partir de primitivos. **Isolado no projeto.** |
| **Prop** | Propriedade configurável de um nó, tipada (string, double, color, enum, edgeInsets, action, child, etc.). |
| **Evento** | Gatilho de interação de um nó (`onTap`, `onLongPress`...). Cada evento dispara **uma lista de ações**. |
| **Ação** | Unidade de comportamento, representada como dado (`type` + `params`). Configurada na web, interpretada no app. |
| **Spec JSON** | Serialização do widget: árvore de nós + props + eventos/ações + contrato de props públicas. IP central. |
| **Catálogo** | Coleção versionada e pesquisável de widgets. |
| **Draft / Versão** | Estado de edição não publicado / snapshot imutável publicado. |
| **Papel / Workflow** | Nível hierárquico do usuário e máquina de estados de aprovação. |

---

## 3. O Spec JSON (núcleo de tudo)

```jsonc
{
  "id": "uuid",
  "slug": "primary_button",
  "name": "Botão Primário",
  "kind": "primitive",            // primitive | composite (composite = fase posterior)
  "version": 3,
  "status": "published",          // draft | in_review | approved | published | deprecated
  "tree": {
    "type": "gestureDetector",
    "props": {},
    "events": {
      "onTap": [
        { "type": "navigate", "params": { "route": "/product", "args": { "id": "{{productId}}" } } },
        { "type": "track",    "params": { "event": "cta_click" } }
      ]
    },
    "child": {
      "type": "container",
      "props": {
        "padding": { "all": 16 },
        "color": "{{bgColor}}",
        "borderRadius": 8
      },
      "child": {
        "type": "text",
        "props": { "data": "{{label}}", "style": { "fontSize": 16, "fontWeight": "w600", "color": "#FFFFFF" } }
      }
    }
  },
  "propsSchema": [
    { "key": "label",     "type": "string", "required": true,  "default": "Comprar" },
    { "key": "bgColor",   "type": "color",  "required": false, "default": "#1565C0" },
    { "key": "productId", "type": "string", "required": true }
  ],
  "metadata": { "createdBy": "...", "updatedBy": "...", "updatedAt": "..." }
}
```

Pontos de design:
- **Binding** `{{prop}}` liga um campo do `propsSchema` a uma prop/param interno. Definido no Builder.
- **`child` vs `children`**: primitivos de um filho (Container, Center, Padding) usam `child`; de múltiplos (Column, Row, Stack) usam `children`.
- **Versão publicada é imutável.** Editar = novo draft → nova versão ao publicar (ver §7).

### 3.1 Eventos e Ações

A ação é **apenas dado**. A web configura, o app interpreta (padrão de *registry* inspirado no Stac).

**Cada nó pode ter eventos; cada evento dispara uma lista ordenada de ações.** O primitivo `GestureDetector` é o ponto de entrada genérico de interação (equivalente ao do Flutter), mas botões e outros nós também expõem eventos.

```jsonc
"events": {
  "onTap":       [ { "type": "...", "params": {} }, { "type": "...", "params": {} } ],
  "onLongPress": [ { "type": "...", "params": {} } ]
}
```

**Tipos de ação (conjunto fechado, definido por nós):**

| type | params | efeito (resolvido pelo app cliente) |
|---|---|---|
| `navigate` | `routeId`, `args` | navegação interna; `routeId` referencia uma **rota cadastrada no projeto** (ver §8.2); `args` preenche os params declarados por ela |
| `openUrl` | `url` | abre página web (`launchUrl`) |
| `goBack` | — | volta |
| `showDialog` | `dialogId`, `params` | abre diálogo registrado |
| `track` | `event`, `props` | telemetria |
| `custom` | `name`, `params` | handler arbitrário registrado pelo cliente |

**Interpretação no app Flutter (dispatcher):**

```dart
SduiActions
  ..register('navigate', (p, ctx) => Navigator.pushNamed(ctx, p['route'], arguments: p['args']))
  ..register('openUrl',  (p, ctx) => launchUrl(Uri.parse(p['url'])))
  ..register('goBack',   (p, ctx) => Navigator.pop(ctx));

// Execução em sequência das ações de um evento
Future<void> dispatch(List<SduiAction> actions, BuildContext ctx) async {
  for (final a in actions) {
    await SduiActions.handlerFor(a.type)?.call(a.params, ctx);
  }
}
```

Princípios: tipos fechados definidos por nós; o **app cliente decide o efeito** (mantém o produto genérico); params suportam binding; **lista de ações executada em ordem**.

---

## 4. Catálogo de Primitivos do MVP

Cada primitivo é um port de um widget Flutter; as props expostas espelham a API oficial do Flutter (a lista abaixo é o subconjunto inicial — a definição completa por primitivo sai da doc do Flutter).

| Primitivo | Filhos | Props principais (espelhando Flutter) |
|---|---|---|
| **Container** | `child` | `width`, `height`, `padding` (EdgeInsets), `margin`, `color`, `alignment`, `borderRadius`, `border`, `boxShadow`, `constraints` |
| **Column** | `children` | `mainAxisAlignment`, `crossAxisAlignment`, `mainAxisSize`, `spacing` |
| **Row** | `children` | `mainAxisAlignment`, `crossAxisAlignment`, `mainAxisSize`, `spacing` |
| **Stack** | `children` | `alignment`, `fit`, `clipBehavior` (+ filhos podem ser `Positioned`) |
| **Text** | — | `data`, `style` (`fontSize`, `fontWeight`, `color`, `fontFamily`, `letterSpacing`, `height`), `textAlign`, `maxLines`, `overflow` |
| **Image** | — | `src`/`url`, `width`, `height`, `fit` (BoxFit), `source` (network/asset) |
| **Icon** | — | `icon` (nome), `size`, `color` |
| **Button** | `child`/`label` | `label`, `onPressed` (evento→ações), `variant` (elevated/text/outlined), `style` |
| **SizedBox** | `child` | `width`, `height` |
| **Padding** | `child` | `padding` (EdgeInsets) |
| **Center** | `child` | `widthFactor`, `heightFactor` |
| **Expanded / Flexible** | `child` | `flex`, `fit` |
| **Spacer** | — | `flex` |
| **GestureDetector** | `child` | eventos: `onTap`, `onLongPress`, `onDoubleTap` |

**Tipos de prop suportados:** `string`, `int`, `double`, `bool`, `color`, `enum`, `edgeInsets`, `boxFit` (e outros enums), `action`/`actionList`, `child`, `children`, `image`.

---

## 5. Anatomia da interface do Builder

```
┌────────────┬──────────────────────────┬───────────────┐
│  PALETTE   │      DEVICE PREVIEW       │   INSPECTOR   │
│ (primitivos│   (Flutter Web em iframe, │ (props do nó  │
│  arrastáveis)│  moldura de dispositivo)│  selecionado) │
├────────────┤                          ├───────────────┤
│   LAYERS   │   [iPhone][Android][Tab] │   PROPS DEF   │
│  (árvore)  │   ← seletor de tamanho   │ (props públicas)│
└────────────┴──────────────────────────┴───────────────┘
```

1. **Palette** — primitivos arrastáveis (componentes Puck).
2. **Canvas/Preview** — edição no Puck + **preview fiel** via Flutter Web (ver §6).
3. **Layers** — árvore de nós (selecionar/reordenar/deletar).
4. **Inspector** — forms dinâmicos por tipo de nó, incl. editor de eventos/ações.
5. **Props Definition** — define o contrato público de props.
6. **Seletor de dispositivo** — alterna tamanhos para testar responsividade.
7. **Topbar** — nome, versão, status, salvar draft, enviar para revisão, publicar.

---

## 6. Preview fiel ao Flutter

**Objetivo:** o que o usuário vê no editor é renderizado pelo **mesmo renderer do app de produção**, não por uma aproximação React.

**Arquitetura:**
1. Um app **Flutter Web** mínimo (`sdui_preview`) embarca o renderer real (`sdui_flutter`).
2. Esse app é servido como asset estático e carregado num **`<iframe>`** dentro do editor React.
3. O editor envia o spec JSON corrente ao iframe via **`window.postMessage`**; o app Flutter escuta, faz parse e re-renderiza.
4. A cada alteração no Puck, o editor recalcula o spec e re-emite a mensagem (com debounce).
5. Uma **moldura de dispositivo** (div com largura/altura por preset: iPhone, Android, tablet) envolve o iframe → teste de responsividade.

```
React (editor)  ──postMessage(spec)──▶  iframe: Flutter Web (sdui_flutter)
              ◀──postMessage(events)──   (altura, taps de preview, erros)
```

Notas:
- Comunicação cross-origin segura via `postMessage` (validar `event.origin`).
- O preview também devolve eventos (ex.: altura do conteúdo, clique simulado) ao editor.
- **Fidelidade 100%** porque o renderer é o de produção; zero divergência React↔Flutter.

---

## 7. Versionamento, Draft e Colaboração

- **Draft**: toda edição cria/atualiza um rascunho associado ao widget e ao autor. O draft pode ser pré-visualizado e testado livremente sem afetar a versão publicada.
- **Publicação incrementa a versão**: ao aprovar/publicar um draft, gera-se uma nova linha imutável em `widget_versions` (`version = current + 1`) e `widgets.current_version` aponta para ela.
- **Imutabilidade**: versões publicadas nunca são editadas; conteúdo que referencia uma versão antiga continua estável.
- **Colaboração**: vários usuários usam o sistema. No MVP, edição é por draft individual; **lock otimista** (campo `updated_at`/`version` + checagem em escrita) evita sobrescrita silenciosa. Colaboração em tempo real fica para depois.

---

## 8. Multi-tenancy, Usuários, Papéis e Fluxo de Aprovação

### 8.0 Multi-tenancy e provisionamento

```
Plataforma (você)
  ├── Primitivos (nível plataforma, leitura para todos)
  └── Projeto A (cliente licenciado)        Projeto B ...
        ├── Widgets do cliente (isolados)
        ├── Usuários, papéis e permissões (escopados ao projeto)
        └── Rotas cadastradas
```

- A plataforma (super-admin) **provisiona um Projeto por licença** vendida.
- Ao criar o projeto, o cliente já recebe acesso de leitura aos **primitivos da plataforma** e pode compor seus próprios widgets a partir deles.
- **Isolamento por `project_id`** em todas as tabelas de domínio do cliente. Permissões sempre escopadas ao projeto (modelo `{app}` do Squidex).
- Um usuário pode pertencer a um ou mais projetos, com papéis distintos em cada.

### 8.1 Papéis e permissões
| Papel | Pode |
|---|---|
| **Reader** | visualizar widgets e catálogo |
| **Creator** | criar/editar drafts, enviar para revisão |
| **Reviewer** | aprovar ou rejeitar drafts em revisão |
| **Publisher** | publicar (gerar versão) e depreciar |
| **Admin** | tudo + gerenciar usuários, papéis e workflow |

### Permissões finas (notação de ponto, estilo Squidex)
```
app.{app}.widgets.*.read
app.{app}.widgets.*.write
app.{app}.widgets.{slug}.publish
app.{app}.users.manage
```

### 8.2 Cadastro de Rotas (por projeto)

Cada projeto cadastra as rotas conhecidas do app do cliente, para alimentar a ação `navigate`.

```jsonc
{
  "id": "route_product_detail",
  "name": "Detalhe do Produto",
  "path": "/product",
  "params": [
    { "key": "id",  "type": "string", "required": true },
    { "key": "tab", "type": "enum",   "options": ["info","reviews"], "required": false }
  ]
}
```

No Builder, a ação `navigate` exibe um **dropdown das rotas cadastradas**; ao escolher uma, o Inspector mostra os `params` declarados para preenchimento (com binding `{{...}}`). No app, o cliente registra o mesmo `path` no SDK e o dispatcher resolve a navegação. Mantém o produto genérico (cada cliente declara suas rotas) e torna `navigate` à prova de erro.

### 8.3 Workflow como máquina de estados
```
draft ──(enviar: Creator)──▶ in_review ──(aprovar: Reviewer)──▶ approved
                                  │                                  │
                          (rejeitar: Reviewer)              (publicar: Publisher)
                                  ▼                                  ▼
                                draft                            published ──(depreciar: Publisher)──▶ deprecated
```
- Cada **transição** tem papéis permitidos: só quem tem o papel move o item para o status alvo (modelo Squidex).
- Transições podem ter **condição** (expressão) — ex.: certos tipos pulam revisão. Fica em aberto para depois.

---

## 9. Stack

| Camada | Escolha | Justificativa |
|---|---|---|
| Frontend editor | **Next.js (App Router) + TypeScript** | Editor e telas de gestão. |
| UI | TailwindCSS + shadcn/ui | Painéis, inputs, modais. |
| Drag-and-drop / canvas | **Puck (MIT)** | Aninhamento via **Slots API**; arrasto em qualquer direção; canvas + inspector prontos. Tradução payload Puck→spec é nossa. |
| Estado do editor | Zustand + Immer + zundo | Árvore imutável + undo/redo. |
| Forms do Inspector | React Hook Form + Zod | Forms dinâmicos validados pelo schema do nó. |
| Color picker / código | react-colorful / @monaco-editor/react | Cores e expressões. |
| Painéis | react-resizable-panels | Layout do editor. |
| **Preview** | **App Flutter Web (`sdui_preview`) em iframe** | Renderer real; fidelidade 100%. Comunicação via `postMessage`. |
| **Backend** | **NestJS (separado) + TypeScript** | Domínio pesado (RBAC, workflow, versionamento) é o núcleo do produto. Next fica só no frontend. |
| ORM / Banco | Prisma + **PostgreSQL (JSONB)** | Spec como JSONB; consultas por slug/status/versão. |
| Auth + RBAC | Better-Auth/Auth.js + **Casbin** | Papéis hierárquicos e permissões finas. |
| Cache/Fila | Redis (+ BullMQ se preciso) | Cache e tarefas. |
| Validação | Zod (compartilhado FE/BE) | Spec validado nos dois lados. |
| Design tokens | **Em aberto** (design system básico) | Não é foco agora; estrutura prevista para evoluir (ver §13). |

> Licenças: Puck (MIT), dnd-kit (MIT), Casbin, Prisma, NestJS — todas permissivas/comerciais. Rodam só na sua infra; não comprometem a propriedade do produto.

---

## 10. Modelo de dados

```sql
-- Nível plataforma
projects (id uuid pk, name text, license_status text, created_at timestamptz)
users (id, email, name, created_at)
primitives (id, type, props_schema jsonb, version int)   -- compartilhado (leitura) com todos os projetos

-- Escopado por projeto
roles (id, project_id fk, name, permissions jsonb)        -- permissões em notação de ponto
user_projects (user_id, project_id, role_id)              -- usuário pode estar em vários projetos

project_routes (
  id uuid pk, project_id fk,
  name text, path text, params jsonb,                     -- params declarados da rota
  unique (project_id, path)
)

widgets (
  id uuid pk, project_id fk, slug text, name text,
  kind text,                                 -- primitive | composite
  status text,                               -- draft|in_review|approved|published|deprecated
  current_version int,
  created_by uuid, created_at timestamptz, updated_at timestamptz,
  unique (project_id, slug)
)

widget_versions (
  id uuid pk, widget_id uuid fk, version int,
  tree jsonb, props_schema jsonb,
  changelog text, created_by uuid, created_at timestamptz,
  unique (widget_id, version)
)

widget_drafts (
  id uuid pk, widget_id uuid fk, author_id uuid,
  tree jsonb, props_schema jsonb,
  base_version int,                          -- versão de origem (lock otimista)
  updated_at timestamptz
)

workflow_transitions (
  id uuid pk, project_id fk, from_status text, to_status text,
  allowed_roles text[], condition_expr text  -- condição opcional
)

audit_log (id, project_id, entity, entity_id, action, user_id, diff jsonb, at timestamptz)
```

> Toda tabela de domínio do cliente carrega `project_id` para isolamento multi-tenant. `primitives` é a exceção: vive no nível plataforma e é lido por todos os projetos.

---

## 11. Funcionalidades — MVP vs. depois

### MVP
- [ ] ~14 primitivos da §4 na Palette (Puck).
- [ ] Canvas com drag-and-drop e aninhamento (Slots).
- [ ] Layers sincronizada.
- [ ] Inspector com forms por tipo + editor de **eventos/ações** (lista de ações).
- [ ] Definição de props públicas + binding.
- [ ] **Preview fiel** via Flutter Web + seletor de dispositivos (responsividade).
- [ ] Draft → workflow de aprovação → publicar (incrementa versão).
- [ ] Usuários, papéis e permissões.
- [ ] Catálogo: listar, buscar, ver versões.

### Depois
- [ ] Compostos nomeados (reusar primitivos).
- [ ] Condições nas transições de workflow.
- [ ] Design system / tokens (`$primary`).
- [ ] Colaboração em tempo real.
- [ ] Expressões avançadas (Monaco).
- [ ] Import/export de spec; templates.

---

## 12. Fases de implementação

1. **Congelar Spec JSON v1** (árvore + props por primitivo + eventos/ações + props públicas).
2. **`sdui_flutter` mínimo** renderizando os primitivos a partir do spec (já reusável no app).
3. **`sdui_preview`** (Flutter Web) + bridge `postMessage`.
4. **Editor base** (Next + Puck): palette, canvas, layers a partir do spec.
5. **Tradução payload Puck ↔ spec** (ida e volta).
6. **Inspector** + editor de eventos/ações.
7. **Preview embarcado** + seletor de dispositivos.
8. **Backend NestJS**: usuários, papéis, permissões (Casbin).
9. **Draft + workflow + versionamento** + auditoria.
10. **Catálogo** (listar/buscar/versões) e polimento.

---

## 13. Decisões

### ✅ Resolvidas
1. Granularidade → só primitivos agora (port do Flutter); compostos depois.
2. Props → espelham os widgets do Flutter (doc oficial).
3. Preview → fiel, via Flutter Web em iframe + `postMessage`, com molduras de dispositivo.
4. Colaboração → multiusuário; edição por draft; publicar incrementa versão; lock otimista no MVP.
5. Tema → design system básico, não é foco; estrutura deixada aberta para evoluir.
6. Responsividade → sim, com teste em múltiplos tamanhos de tela.
7. Backend → **NestJS separado**; Next só no frontend.
8. Usuários → papéis hierárquicos + permissões finas + aprovação no fluxo (modelo Squidex).
9. Ações → cada nó pode ter eventos; cada evento dispara **lista de ações** (GestureDetector como gatilho genérico).
10. Multi-tenant → **um projeto por licença**, provisionado pela plataforma; primitivos compartilhados em leitura, widgets do cliente isolados por `project_id`.
11. `navigate` → o cliente **cadastra rotas (path + params) no projeto**; o Builder oferece dropdown e preenche os params declarados.
12. Props por primitivo → definidas no documento **`spec-json-v1.md`** (props/enums espelhando o Flutter).
13. Condições no workflow → **pós-MVP**.
14. Design system → esqueleto definido em `spec-json-v1.md` §5 (tokens de cor, escala tipográfica e de espaçamento); valores livres até os tokens entrarem.
15. Provisionamento de projeto → **manual pelo super-admin** (plataforma) no MVP. Self-service fica para avaliação futura, sem bloquear nada.

### ⬜ Em aberto
_Nenhuma decisão estrutural pendente. As próximas definições são de implementação (fatia vertical dos primitivos)._

---

## 14. Riscos

- **Spec instável** → migração custosa após widgets salvos. Mitigar com versionamento de schema do spec desde o v1.
- **Tradução Puck↔spec** → ponto de atrito; manter a conversão isolada e bem testada (ida e volta idempotente).
- **Preview Flutter Web** → custo de build/carregamento do iframe; mitigar com app de preview enxuto e cache.
- **Escopo do workflow/RBAC** → pode inflar; começar com os 5 papéis e transições fixas, condições depois.
