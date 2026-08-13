# docs/plans — planejamento por item do roadmap

Um plano por item **aberto** do [`docs/roadmap.md`](../roadmap.md). Cada pasta guarda o `plan.md`: fases numeradas, arquivos/classes/métodos que nascem ou mudam, precedências, critério de aceite validável **antes** de codar e o mapa do que dá para tocar em paralelo.

**Por que existe.** O método do projeto (`CLAUDE.md` › _Método de trabalho_) diz que 1 fase = 1 PR e que desvio de plano só entra com aprovação registrada. Para isso o plano precisa existir antes. Estes planos são a versão "de gaveta": quando o item entra em execução via `/tech-manager`, o PM/tech-lead abrem a doc viva em `docs/NN-<nome>/` **partindo daqui** — o plano de gaveta é a matéria-prima do `plan.md` vivo, não um concorrente dele.

**Regra do "pronto" em todos eles:** `flutter analyze` verde + `dart test`/`flutter test` existentes passando + (quando toca backend) `pnpm build` verde. Nunca opinião.

## Índice

| Item | Assunto | Plano | Depende de |
| --- | --- | --- | --- |
| 23 | Histórico do editor (undo/redo, atalhos, duplicar/colar) | [`23-historico-editor`](23-historico-editor/plan.md) | — |
| 24 | Publicação e versionamento do conteúdo | [`24-publicacao-versionamento`](24-publicacao-versionamento/plan.md) | — |
| 25 | Entrega ao app cliente (API pública + runtime + exemplo) | [`25-entrega-app-cliente`](25-entrega-app-cliente/plan.md) | 24 |
| 26 | Autenticação e multi-tenant real | [`26-auth-multi-tenant`](26-auth-multi-tenant/plan.md) | 25 (convive) |
| 27 | Storage S3/Garage ligado | [`27-storage-garage`](27-storage-garage/plan.md) | 26 |
| 28 | Eventos e ações editáveis | [`28-eventos-acoes`](28-eventos-acoes/plan.md) | 25 |
| 29 | Contexto de dados e binding com contrato | [`29-contexto-de-dados`](29-contexto-de-dados/plan.md) | 28 |
| 19 | Home com Conteúdos e Componentes | [`19-home-conteudos-componentes`](19-home-conteudos-componentes/plan.md) | 24 |
| 20 | Componente com construtor próprio | [`20-componente-construtor`](20-componente-construtor/plan.md) | 19 |
| 21 | Aba "Componentes" no editor | [`21-aba-componentes-editor`](21-aba-componentes-editor/plan.md) | 20 |
| 22 | Metadados e listagem de componentes | [`22-metadados-componente`](22-metadados-componente/plan.md) | 20, 21 |
| 17 | Offline-first na tela de conteúdos | [`17-offline-first`](17-offline-first/plan.md) | — |
| 18 | Pull-to-refresh que refaz o cache | [`18-pull-to-refresh`](18-pull-to-refresh/plan.md) | 17 |
| 9 | Catálogo de widgets (track contínuo) | [`09-catalogo-widgets`](09-catalogo-widgets/plan.md) | — |
| 8b | Legibilidade avançada do JSON | [`08b-legibilidade-json`](08b-legibilidade-json/plan.md) | — |
| 30 | Responsividade por breakpoint | [`30-responsividade-breakpoints`](30-responsividade-breakpoints/plan.md) | — (antes do 20) |

## Costuras entre planos (resultado da revisão cruzada de 2026-08-13)

Decisões que atravessam mais de um item. **Quem executar primeiro deixa a estrutura pronta para os outros** — a coluna "quem paga" diz onde o trabalho nasce dependendo da ordem escolhida.

| Costura | Planos | Quem paga |
| --- | --- | --- |
| `diagnoseTree` precisa de mais contexto (slugs conhecidos, spec inteiro) | 21, 28, 29 | Assinatura final acordada: `diagnoseTree(ContentSpec spec, {Set<String> knownSlugs})`. O primeiro a executar já adota. |
| `_emitDocument` recebendo `ContentSpec` em vez de `SduiNode?` | 23, 29 | Melhor nascer assim no 23 — fecha o buraco do `updateSafeAreaProps` por construção. |
| `cloneWithNewIds` (clonagem de subárvore com ids novos) | 23, 21 | Quem chegar primeiro cria; o outro encontra pronto. Assinatura idêntica nos dois. |
| `InspectorPanel`: três modos e dois `TabBar` diferentes | 20, 28, 29 | `InspectorPageMode` selado + `InspectorTabs` comum. O primeiro deixa a estrutura. |
| Rota pública de mídia `/v1/media/:key` (capas não sobrevivem ao guard de auth) | 26, 27, 22 | Nasce no 27 (D3); se o 26 vier antes, nasce lá — **senão as capas quebram em produção**. |
| Chave do cache local precisa de `kind` e de `userId` | 17, 19, 26 | A chave do 17 já reserva os campos; 19 e 26 são obrigados a preenchê-los. |
| Campos novos em `ContentSummary` vs cache em disco antigo | 24, 17 | Todo campo novo entra com **default tolerante** no zard, senão o cache antigo derruba a lista. |
| Publicar = expandir componentes antes de enviar | 24, 21 | O `PublishContentUseCase` do 24 nasce como transformador, não passa-fica. |
| Rota pública não pode servir componente como se fosse tela | 25, 19 | Filtro `kind: 'content'`; nasce no 19 se o 25 vier antes. |
| Ordem das transformações de prop no renderer | 29, 30 | Breakpoint achata **antes** do binding resolver, na mesma passagem de `_SduiNodeView`. |
| `coalesceKey` do histórico precisa de namespace por origem | 23, 28, 29, 30 | `props:` / `event:` / `data:` / + breakpoint ativo. Sem isso, undo colapsa edições distintas. |

## Convenções de todo plano

- **Precedências primeiro.** Cada fase declara o que já precisa existir. Nenhuma fase chama classe, método, rota ou tabela que uma fase anterior (ou plano anterior) não tenha criado — é a regra que impede o plano de "chamar o que não foi instanciado".
- **`[∥]` marca o que roda em paralelo.** Fases sem aresta entre si podem virar PRs simultâneos por pessoas/agentes diferentes.
- **Fatia vertical quando o contrato muda.** Se um PR muda o formato de resposta da API, o `data`/`domain` do editor que consome vai **no mesmo PR** — a lição do envelope `{data,nextCursor}` (`docs/08.../plan.md` › restrição dura).
- **Testes por último.** A bateria automatizada é escrita depois do E2E atestado (cap. 22 do livro). Cada plano lista o que testar, mas a fase de teste é sempre a última.
- **E2E exercita a UI real no ambiente real.** Não `localhost`, não só contrato de API — a lição registrada no item 9g.
