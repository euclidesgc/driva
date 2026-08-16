# Roadmap — driva

Rastreamento vivo do que está **feito**, **em andamento** e **por fazer**. A lista está ordenada **por dependência**: o que vem antes destrava o que vem depois. Cada item traz, entre parênteses, o número original em `docs/03-melhorias/` para rastreabilidade.

**Legenda:** `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída.

> **Documento vivo.** Mantido atualizado pela IA a cada fechamento de trabalho (junto da faxina de branches): marca o item entregue como `[x]`, o item da vez como `[-]`, e — quando surgem features novas — reescreve o texto para dar clareza e **reordena** para o ponto de precedência correto. Ver `CLAUDE.md` › _Método de trabalho_.

> **Todo item aberto tem um plano.** Cada item por fazer aponta para uma pasta em **`docs/plans/<NN>-<slug>/plan.md`** com o planejamento detalhado (fases, arquivos, classes, métodos, precedências e o que dá para paralelizar) — escrito **antes** de codar, para que a entrega possa ser validada no papel. Índice: [`docs/plans/README.md`](plans/README.md). Quando a feature entra em execução, a doc viva do trabalho (`docs/NN-<nome>/`) nasce a partir do plano.

---

## Ordem de execução recomendada

O que destrava o quê, em uma linha. Os números são identidade do item (histórica), **não** posição na fila.

```
38 (drop sem beco sem saída) ─┐
39 (image: erro visível)      ├─► 24 (publicação) ─► 25 (entrega ao app) ─► 26 (auth) ─► 27 (storage)
23 (histórico/undo) ──────────┤                    │
 9 (catálogo, contínuo) ──────┘                    ├─► 28 (eventos/ações) ─► 29 (dados/binding)
                                                   │
                                                   └─► 19 ─► 20 ─► 21 ─► 22 (componentes)

17 ─► 18 (offline-first)     8b (JSON)     30 (breakpoints)      ← independentes, encaixáveis quando fizer sentido
```

**O gargalo do produto hoje é o item 24 + 25**: o driva ainda não entrega conteúdo para app cliente nenhum. Tudo entregue até aqui é o lado do editor.

**Na frente do 24, dois defeitos do uso real (2026-08-15).** Os itens **38** e **39** não são pré-requisito técnico da publicação — entram antes porque são 0-dep, não tocam backend e travam quem usa o editor hoje: o 38 deixa a página **sem saída** depois de um drop recusado (a única alternativa apaga o conteúdo inteiro) e o 39 faz a imagem falhar em silêncio, indistinguível de "sem URL".

---

## Base já entregue

- `[x]` **Fundação I1 — Conteúdos (rename página→conteúdo + identidade slug/CUID2).** No ar em homologação; renderer SDUI, editor de 3 painéis, catálogo com 24 widgets, backend `/v1/contents`. É o alicerce sobre o qual todo o resto abaixo é construído.

---

## Marco 0 — Fundação e correções que destravam tudo

_Sem dependências entre si; vieram primeiro porque tornam todo o resto viável ou agradável de construir._

- `[x]` **1. Corrigir o bug de foco no Inspector (0-dep).** _(item 16)_ Ao digitar em qualquer campo de propriedade (ex.: elevação do card), o editor perdia o foco após cada tecla e exigia reclicar. Causa: a `ValueKey` do `TextFormField` incluía o valor, então cada `onChanged` recriava o campo. **Precede o item 9 (catálogo)** — sem isso, editar propriedades era inviável.
- `[x]` **2. Enxugar loadings e rebuilds da navegação.** _(item 10)_ Create navega direto ao editor (sem `await load()`/spinner) e exclusão otimista (card some na hora, reconcilia em falha). Docs em `docs/05-loadings-navegacao/`.
- `[x]` **3. Tema light + dark com persistência.** _(item 0)_ Introduziu a camada de preferências local (`preferences_module`, `shared_preferences`) que o **item 17 (offline-first)** reaproveita.
- `[x]` **3b. Aliviar o peso do editor ao digitar/arrastar (escopo de rebuilds).** _(perf; surgiu do uso)_ Rebuilds escopados por painel (`BlocSelector`/`buildWhen`), canvas isolado (`RepaintBoundary`) e preview caro throttlado, mantendo campo e estado instantâneos.

## Marco 1 — Polimento do construtor (canvas)

- `[x]` **4. Altura máxima do mock do dispositivo.** _(item 12)_ ~~Limitar a altura do mock.~~ **Revertido:** o teto encolhia o dispositivo em janelas baixas; o **zoom** (80%) já resolve o encaixe.
- `[x]` **5. Feedback visual ao soltar um componente no mock + realce no hover.** _(item 11)_
- `[x]` **6. Molduras de dispositivo realistas.** _(item 13)_
- `[x]` **7. Painel de preview do JSON em tempo real.** _(item 14)_
- `[x]` **8. JSON somente-leitura, copiável e com syntax highlight.** _(item 15)_
- `[ ]` **8b. Legibilidade avançada do JSON.** _(polimento; surgiu do review)_ Números de linha já entregues; falta destacar a **chave-pai** e casar `{`/`}` (abre/fecha) quando o cursor está próximo, e permitir **dobrar seções**. Baixa prioridade, 0-dep. → **[plano](plans/08b-legibilidade-json/plan.md)**
- `[x]` **8c. Raiz livre (página nasce vazia; 1º widget vira a raiz).** _(estilo FlutterFlow)_ `ContentSpec.root` opcional; o primeiro widget adicionado — de qualquer tipo — vira a raiz.
- `[x]` **8d. Raiz folha mostra o estado-vazio em vez de renderizar.** _(bug; `09f3bf7`)_ Condição virou só `root == null`. Coberto por teste de regressão em `editor_perf_test.dart`.

## Marco 1b — Manipulação direta no construtor

- `[x]` **8e. Mover widgets no mock + barra de status de problemas.** _(docs/12)_ Todo nó virou origem e destino de arraste; frestas de inserção na árvore; `resolveDrop` (kernel) como regra única dos dois painéis; rodapé com os problemas do documento (`diagnoseTree`).
- `[x]` **8f. Área segura obrigatória em toda página.** _(docs/12)_ `SafeArea` como **chrome da página** (`ContentSpec.safeArea`), fora do catálogo; o mock injeta o recuo real do dispositivo no `MediaQuery`.

## Marco 2 — Catálogo de widgets (track contínuo)

- `[-]` **9. Ampliar o catálogo usando o FlutterFlow como referência.** _(item -1)_ Track contínuo que alimenta paleta e Inspector; hoje **24 primitivos**. Novo primitivo = descriptor + builder + fixture, nada hardcoded no editor. → **[plano](plans/09-catalogo-widgets/plan.md)** (inclui o processo repetível "como adicionar um widget" + a fila priorizada de primitivos)
  - **Incremento 1 (entregue):** `textField`, `switch`, `checkbox`.
  - **Incremento 2 (entregue):** `textField` abrangente — `borderStyle`, `keyboardType`, `maxLength`, `prefixIcon`.
  - **Incremento 3 (entregue):** `radio`, `dropdown`, `slider`.
  - **Próximos incrementos:** ver a fila no plano.
  - `[-]` **Incremento 4: `image` abrangente** — entra junto com o item 39 (`alignment`, raio, `DimensionValue` em `width`/`height`, e o resto do básico que o `container` já tem e o `image` não).
- `[-]` **39. Widget `image` — a URL aparece, e o editor de propriedades cresce.** _(relato do uso real, 2026-08-15; 0-dep até a F2)_ Duas coisas no mesmo item, e o plano as separa: **o defeito** (informar uma URL não exibe a imagem e o editor **não diz por quê**) e **o catálogo** (o `image` tem 4 propriedades contra 12 do `container` — vira o **Incremento 4** do item 9). Docs vivas em `docs/16-image-url-e-props/`. → **[plano de gaveta](plans/39-image-url-e-props/plan.md)**
  - `[x]` **F1 — a imagem que falha para de mentir** _(2026-08-15; PR #128)_ O `errorBuilder` desenhava o mesmo quadrado cinza do estado "sem URL": falha de rede, host bloqueado por CORS e campo vazio eram pixel a pixel idênticos. Os três estados passam a se distinguir **por forma**. O carregando usa `frameBuilder`, não `loadingBuilder` — no Flutter Web `Image.network` não emite `ImageChunkEvent`, então o estado só existiria no mobile (D12). Nasce `SduiRenderer.showDiagnostics` (default `false`, só o editor liga): o renderer é o mesmo nos dois lados, e URL com token na query string não pode chegar à tela do usuário final — nem tirar o `src` bastava, porque o `toString()` da `NetworkImageLoadException` embute a URI (D13). Junto: `min: 0` → `min: 1` em `width`/`height` e o clamp com sinal no `NumberEditor`. **Não resolve o relato** — o host sem CORS continua falhando; carregá-lo é a F3.
  - `[ ]` **F2 — proxy de mídia no backend** ⚠️ **CISO obrigatório.** `GET /v1/media/proxy?url=` com allowlist de esquema, bloqueio de IP privado/loopback/link-local (`169.254.169.254` incluso), revalidação **a cada redirect**, teto de tamanho, timeout, validação de `Content-Type` e rate limit. Escolhido pelo humano sobre o `WebHtmlElementStrategy.fallback`, que viraria platform view **não capturável por screenshot** — e quebraria o próprio print que prova a correção. **O item 39 deixa de ser "não toca backend" aqui.**
  - `[ ]` **F3 — o resolver no renderer + injeção no editor.** `SduiImageUrlResolver` opcional, no padrão do `showDiagnostics`: o editor injeta, o app cliente não. Sem isso, todo app publicado passaria a puxar imagem pelo nosso backend — banda e ponto único de falha, e inútil, porque em celular não há CORS (D11).
  - `[ ]` **F4 — `image` abrangente** (o Incremento 4 do item 9) · `[ ]` **F5 — bateria**
- `[x]` **9b. Editores de propriedade avançados no Inspector (estados + binding).** Estados múltiplos por propriedade (`padding`/`margin`, `DimensionValue`, `AlignmentValue`) e **binding por propriedade** (`isBindable` + `SduiBinding` no kernel), enum como grupo de ícones, slider com faixa, "voltar ao padrão", seções colapsáveis e busca de propriedade.

## Marco 3 — Hierarquia Projeto → Categoria → Conteúdo (o fluxo do protótipo)

- `[x]` **9d. CRUD de Projeto — novo topo da hierarquia.** _(docs/09)_ Home de cards, upload de imagem (pipeline CISO aprovado), `Content.projectId` FK NOT NULL. **Débitos abertos, agora itens próprios do roadmap: auth (item 26) e storage Garage (item 27).**
- `[x]` **9e. Arquivar projeto (soft delete) + área de Arquivados.** Exclusão em duas camadas, cascata explícita em `$transaction`, confirmação dupla.
- `[x]` **9f. Projetos quebrado em homologação — corrigido e validado no hml.** Três quebras independentes do #43 (diálogo, Dockerfile, `express` não declarado); PRs #46/#47.
- `[x]` **9g. E2E reutilizável da hierarquia de Projetos.** `e2e_hml.sh` (18/18) + `e2e_shots.sh`/`e2e_drive.mjs` dirigindo a **homologação real**, não localhost.
- `[x]` **10. API de conteúdos com filtro, busca, ordenação e paginação + fundação de Categoria.** _(item 7; docs/08)_ Envelope `{data,nextCursor}` com cursor keyset, tabela `Category` em árvore, "Geral" por projeto.
- `[x]` **11–14. Tela do projeto:** árvore de categorias, "Todos os conteúdos" como entrada de topo, filtro por categoria e mover conteúdo entre categorias. _(itens 1, 6, 3, 2)_
- `[x]` **15. Busca e ordenação de conteúdos no painel.** _(item 4)_
- `[x]` **16. Listagem infinita (paginação por cursor).** _(item 5)_
- `[x]` **16b. Nome da categoria no card de conteúdo.** _(docs/11)_
- `[x]` **16c. AppBar global de duas faixas + breadcrumb (via `ShellRoute`).** _(PR #71)_ Chassi único no topo de todas as telas; mecanismo de **slot** em `core/widgets/app_shell/` — a página publica crumbs/ações como dados, o shell nunca lê cubit.

---

## Marco 4 — Ergonomia do construtor

_0-dep. Barato perto do ganho: é o que separa "dá para brincar" de "dá para trabalhar o dia inteiro"._

- `[x]` **23. Histórico do editor — desfazer/refazer, atalhos e duplicar/copiar/colar.** _(surgiu do uso; 0-dep)_ Entregue em `develop` nas quatro fases do plano: #111 (`cloneWithNewIds` no kernel), #112 (pilha de histórico no `EditorCubit`, com coalescing por chave, teto de 50 e reconciliação do status de salvamento), #116 (`EditorShortcuts` — `Ctrl+Z`/`Ctrl+Shift+Z`/`Ctrl+Y`/`Escape`, botões no topo e a guarda de foco), #114 (duplicar/copiar/colar) e #115 (bateria). De carona, dois defeitos que estavam no ar: `Delete` com o cursor num campo do Inspector apagava o **nó selecionado** (o `Shortcuts` do editor vence o `DefaultTextEditingShortcuts`), e o `updateSafeAreaProps` emitia fora do funil de mutação — `_emitDocument` passou a receber o `ContentSpec` inteiro, o que também é o que o item 29 precisa. **Pendente:** E2E manual em homologação (o merge em `develop` disparou o deploy). → **[plano](plans/23-historico-editor/plan.md)**
- `[-]` **38. Destravar o construtor — envolver um nó e drop sem beco sem saída.** _(relato do uso real, 2026-08-15; 0-dep)_ **É a metade que falta do item 8c.** Desde que a raiz virou livre, ela pode ser uma **folha** (`text`, `image`…), e o 8e fez o encaixe subir para o primeiro ancestral que aceita filhos — mas ninguém escreveu o que acontece quando a subida **não acha ancestral nenhum**: `resolveDrop` devolve `noSlotAvailable`, o gesto é recusado e a página fica sem saída. O dev não consegue criar o contêiner que faltava nem tirar de lá o widget que já está; a única saída é excluir a raiz, **que apaga o conteúdo inteiro sem aviso**. Entra a operação de **envolver um nó** no kernel (`wrapNode`), o comando explícito "Envolver em Column/Row" no editor, o `resolveDrop` devolvendo **`DropRequiresWrap`** em vez de recusar (o drop agrupa sozinho, desfazível num `Ctrl+Z`), a **marcação de problema no próprio nó** (árvore e canvas, hoje só no rodapé) e o rótulo honesto no excluir da raiz. Docs vivas em `docs/15-destravar-construtor/`. → **[plano de gaveta](plans/38-destravar-drop-e-envolver/plan.md)**
  - **As 6 fases estão em `develop`** _(2026-08-15)_, entregues como **stack de PRs** — #120 (`wrapNode`), #121 (comando + `Ctrl+G`), #122 (F3+F4, o drop agrupa; PR único por **VR-15-01**, porque `DropResolution` é `sealed` e o caso novo quebra os `switch` do cubit no mesmo instante), #123 (marcação no nó) e #125 ("Esvaziar conteúdo"). E2E instrumentado e verde contra a homologação real em #127.
  - `[ ]` **Pendente do humano: atestar o E2E.** Roteiro e prints em `docs/15-destravar-construtor/`. O único passo que máquina nenhuma cobre é o **`Ctrl+G` num Chrome de verdade** — teclado sintético por CDP não passa pelo caminho do teclado real, que foi como o `Ctrl+Shift+W` original passou por implementado sem nunca disparar.
  - `[ ]` **F7 — bateria automatizada**, depois do E2E atestado (regra do cap. 22). O que está sem rede está listado na F7 do plano; o mais relevante é o braço `DropRequiresWrap` do `moveNode`, **alcançável pelo usuário**.

## Marco 5 — Ciclo de vida do conteúdo (o gargalo do produto)

_Aqui o driva deixa de ser um editor e vira uma plataforma: alguém do outro lado passa a consumir o que foi montado._

- `[ ]` **24. Publicação e versionamento do conteúdo.** _(o botão "Publish" hoje é um placeholder literal — `tooltip: 'Publicação chega no incremento I4'`)_ **Ficou urgente:** a fatia 1 do item 25 já está no ar servindo o **rascunho** para o app cliente, porque a separação ainda não existe. Um `Content` tem **um** campo `spec`: salvar é publicar, e um app em produção leria o mesmo registro que o editor está mexendo. Entra a separação **rascunho × publicado**, a tabela de **versões** (histórico imutável, com autor e data), o **publicar** (promove o rascunho a versão publicada) e o **rollback** (republica uma versão antiga). Pré-requisito duro do item 25. → **[plano](plans/24-publicacao-versionamento/plan.md)**
- `[-]` **25. Entrega ao app cliente — API pública de leitura, runtime SDK e app de exemplo.** `DrivaContent` no `sdui_flutter` hoje é um `throw UnimplementedError` explícito. Entra o `GET` público por slug (só versão **publicada**, com `ETag`/cache e chave publicável por projeto), o runtime (`Driva.init` + `DrivaContent(slug:)` com cache em disco e fallback embarcado) e um **app de exemplo** que prova o ciclo fim-a-fim. → **[plano](plans/25-entrega-app-cliente/plan.md)**
  - `[x]` **Fatia 1 — API pública + app de demonstração** _(2026-08-15; docs/13-loop-sdui)_ **O loop SDUI fechou:** `GET /v1/public/contents[/:slug]` com **chave publicável** (`Project.publishableKey`, header `x-driva-key`), `ETag`/`304` e CORS só nesse prefixo; `apps/driva_demo_app` consome e renderiza com `SduiView` — primeiro consumidor externo do renderer. E2E de contrato 17 PASS/0 FAIL + prints do app renderizando. **Desvio registrado:** foi entregue **antes do item 24**, então serve o rascunho e não uma versão publicada (`variance_report.md` VR-13-01) — não abrir para cliente real antes do 24.
  - `[ ]` **Fatia 2 — runtime empacotado (`driva_client`)**: cache em disco, *stale-while-revalidate*, fallback embarcado e degradação quando o `specVersion` do servidor é mais novo que o do app. **O consumo real elegeu isto como o mais perigoso** (app na loja não se atualiza). Depende do item 24.

## Marco 6 — Produção de verdade

_Débitos assumidos por decisão do humano em 2026-07-09 (`docs/09-crud-projeto/variance_report.md`). O limite registrado: **auth entra antes de abrir para usuários reais**._

- `[ ]` **26. Autenticação e multi-tenant real.** Hoje o "auth" é o header `x-project-id` — qualquer um que saiba um id lê e escreve o projeto inteiro. Entra usuário/sessão, vínculo usuário↔projeto e o escopo de tenant deixando de vir do cliente. Impacta **todos** os controllers do backend e o `DioClient`/`ProjectScope` do editor. → **[plano](plans/26-auth-multi-tenant/plan.md)**
- `[ ]` **37. SaaS: organizações, permissões, chaves e webhooks.** _(pedido do humano, 2026-08-14)_ O que transforma o item 26 em produto multi-cliente: **organizações** com convite de usuários e **papéis** (quem edita, quem só vê, quem publica), **gestão das chaves de acesso** (a `publishableKey` já existe desde a fatia 1 do item 25 — falta rotação, revogação e chave por ambiente), a **área de administração** onde isso tudo é operado, e **webhooks** para avisar sistemas de fora quando algo acontece (conteúdo publicado, variável alterada, experimento iniciado), com entrega assinada, reentrega em falha e log. Depende do item 26. ⚠️ **precisa de refinamento**, com **CISO obrigatório** em cada fase.
- `[ ]` **27. Storage S3/Garage ligado.** A pipeline de imagem e a `StorageService` já existem com implementação local; falta apontar para o **Garage** (`s3.bmjtech.duckdns.org`), com key `<projectId>/midias/<uuid>.<ext>` e credenciais só via env no Coolify. Depende do item 26 (decisão registrada). → **[plano](plans/27-storage-garage/plan.md)**

## Marco 7 — Interatividade (o spec deixa de ser estático)

- `[ ]` **28. Eventos e ações editáveis no Inspector.** `SduiAction` e o `renderer.dispatch` existem no kernel, mas **só o `button` dispara** e **nada no editor edita eventos** — um botão montado no editor não faz nada. Entra o catálogo de eventos por widget (no `WidgetDescriptor`), o catálogo de ações (navegar, abrir URL, mostrar mensagem, chamar API), o editor de eventos no Inspector e o dispatch no renderer. Depende do item 25 para ter sentido de ponta a ponta (é o app cliente quem executa a ação). → **[plano](plans/28-eventos-acoes/plan.md)**
- `[ ]` **29. Contexto de dados e binding com contrato.** `{{expressão}}` já é reconhecida e editável (item 9b), mas nada define **o que existe** para bindar: o campo é texto livre e o renderer não resolve. Entram os **parâmetros da página**, a **fonte de dados** por conteúdo e a resolução do binding no renderer, com o Inspector oferecendo as chaves disponíveis em vez de texto livre. Depende do item 28. → **[plano](plans/29-contexto-de-dados/plan.md)**
- `[ ]` **31. Fontes de dados: API como origem de propriedades.** _(pedido do humano, 2026-08-14)_ Declarar no editor uma chamada HTTP (URL, método, cabeçalhos, auth) e **mapear** a resposta para o contexto de dados, para o conteúdo exibir dado real (lista de produtos, nome do usuário, saldo). Inclui estado de carregando e de falha. É o item 29 puxado até a origem: lá se define **o que existe** para bindar; aqui, **de onde vem**. ⚠️ **precisa de refinamento** — **CISO obrigatório**: segredo de API nunca pode descer para o app.
- `[ ]` **32. Gatilhos e ciclos de vida.** _(pedido do humano, 2026-08-14)_ Os "lugares" onde algo dispara, espelhando o modelo mental do Flutter, em quatro escopos: **app** (ao iniciar), **projeto**, **conteúdo** (ao abrir, antes do build, depois do build, ao fechar) e **componente** (init, dispose). Um gatilho amarra um momento a uma ação do item 28 — "ao abrir o conteúdo, buscar a fonte X e preencher o contexto". Sem isso, ação só existe presa a toque de widget. Depende dos itens 28 e 31. ⚠️ **precisa de refinamento.**

## Marco 7b — Variáveis remotas e testes A/B (o driva vira ConfigCat + Firebase A/B)

_Pedido do humano em 2026-08-14, com a referência declarada: **ConfigCat** (variáveis remotas) e **Firebase A/B Testing** (experimentos). Depende do runtime existir (item 25) — variável só vale se alguém a resolve no cliente — e do contexto de dados (item 29), que é onde ela aterrissa._

> ⚠️ **Todo este marco precisa de refinamento.** Decisões de produto pesadas; nada entra em implementação antes de discovery + specs/prd.

- `[ ]` **33. Variáveis remotas por projeto e por conteúdo.** Chave/valor **tipado** (bool, número, texto, JSON) com valor padrão, definidas no editor e entregues ao cliente junto do spec. Dois escopos: variável do **projeto** (vale para tudo) e do **conteúdo** (sobrescreve). Muda o comportamento do app **sem republicar** — é o que separa "spec estático" de "configuração viva". Base dos itens 34–35. ⚠️ refinar.
- `[ ]` **34. Variável como valor de propriedade.** Qualquer prop `isBindable` passa a aceitar uma variável como origem, na mecânica de `{{...}}` que o Inspector já tem (item 9b), resolvida em runtime; o editor mostra o **valor padrão** no preview e sinaliza que aquilo é dinâmico. Depende dos itens 33 e 29. ⚠️ refinar.
- `[ ]` **35. Testes A/B sobre as variáveis.** Experimento = **variantes** de uma ou mais variáveis + regra de distribuição + público-alvo. O difícil não é sortear: é a **consistência** (o mesmo usuário vê sempre a mesma variante, inclusive offline e entre sessões), a **unidade de sorteio** (usuário? dispositivo? instalação?), a convivência de experimentos simultâneos e a métrica que diz quem ganhou. Depende do item 33. ⚠️ refinar — provavelmente vira marco próprio no refinamento.

## Marco 8 — Componentes (widgets reutilizáveis)

_A maior frente. Depende do construtor maduro (Marcos 1–2, 4) e da hierarquia (Marco 3). Ganha muito se vier depois do ciclo de publicação (24/25), porque componente publicado tem os mesmos problemas de versão._

- `[ ]` **19. Home passa a exibir Conteúdos e Componentes.** _(item 17)_ Divisão de nível superior entre as duas coisas dentro da tela do projeto. → **[plano](plans/19-home-conteudos-componentes/plan.md)**
- `[ ]` **20. Componente como widget reutilizável, com construtor próprio.** _(item 18)_ Mesma premissa de Conteúdo; um componente é um widget que poderá ser usado dentro de um conteúdo. Depende do item 19. → **[plano](plans/20-componente-construtor/plan.md)**
- `[ ]` **21. Aba "Componentes" no editor, ao lado de Widgets e Árvore.** _(item 19)_ Componentes do projeto ficam disponíveis para uso no construtor de conteúdo, com instância por referência. Depende do item 20. → **[plano](plans/21-aba-componentes-editor/plan.md)**
- `[ ]` **22. Metadados e listagem de componentes no padrão da lista de Widgets.** _(item 20)_ Ao salvar um componente, escolher categoria e definir ícone/imagem, para ele aparecer bonito na lista como os widgets. Depende dos itens 20 e 21. → **[plano](plans/22-metadados-componente/plan.md)**
- `[ ]` **36. Área exclusiva de construção de componentes personalizados.** _(pedido do humano, 2026-08-14)_ Um espaço dedicado — não o construtor de conteúdo com outro chapéu — para criar o componente, definir suas **propriedades públicas** (o que quem usa poderá configurar), pré-visualizar em isolamento e publicá-lo na lista. A decisão central é a modelagem dessas props públicas: é o **contrato** do componente, e é o que decide se ele aparece na paleta como um primitivo de verdade. Depende dos itens 20–22. ⚠️ **precisa de refinamento.**

## Marco 9 — Offline-first

> **Correção do humano (2026-08-14):** offline-first e pull-to-refresh são, antes de tudo, do **SDK do cliente** — é o app do cliente que precisa abrir sem rede e revalidar. Os itens 17/18 abaixo continuam valendo para o **editor** (a lista de conteúdos), mas a versão que importa para o produto é a do runtime, e ela vive na **fatia 2 do item 25**.

- `[ ]` **17. Offline-first na tela de conteúdos (editor).** _(item 8)_ Cache local da lista; atualiza ao salvar. Depende da lista já com filtro/busca/paginação (itens 13–16, entregues) e reaproveita a persistência do item 3. → **[plano](plans/17-offline-first/plan.md)**
- `[ ]` **18. Pull-to-refresh que refaz o cache (editor).** _(item 9)_ Depende do item 17. → **[plano](plans/18-pull-to-refresh/plan.md)**

## Track contínuo — encaixáveis a qualquer momento

- `[ ]` **30. Responsividade — o spec ganha variação por breakpoint.** _(surgiu da análise; 2026-08-13)_ O mock tem presets de dispositivo, mas o spec descreve **uma** tela: o mesmo JSON vai para celular e tablet sem alternativa. Entra o conceito de override por breakpoint em props selecionadas, com o canvas mostrando qual breakpoint está sendo editado. Independente, mas **mais barato antes** dos componentes (item 20) — depois, cada componente precisaria migrar junto. → **[plano](plans/30-responsividade-breakpoints/plan.md)**
- `[ ]` **40. O `backend/` ganha bateria de testes de verdade.** _(surgiu da F2 do item 39, 2026-08-15)_ Até o proxy de mídia, **o backend não tinha infraestrutura de teste nenhuma** — `jest`, `ts-jest`, `supertest` e `@nestjs/testing` nasceram ali de carona, junto de uma feature que precisava provar 11 controles de segurança. Dois sintomas disso já foram corrigidos na própria fase (o `jest-e2e.json` reintroduzia `commonjs`/`node`, o par que o time migrou de propósito para `nodenext`; e a suíte redeclarava o bootstrap em vez de reusar o `main.ts`, então a asserção de CORS testava uma cópia) — mas o buraco de fundo continua. **Entra:** cobertura dos módulos que já existem (`contents`, `projects`, `categories`, `public`, `storage`) e o backend na mesma régua que o Flutter, em vez de só `pnpm build`. **Enquanto não for item, isso continua nascendo de carona na próxima feature que precisar** — que é exatamente como chegou aqui.

---

## Débitos e riscos vivos (não são itens, são vigilâncias)

| Assunto | Estado | Onde está registrado |
| --- | --- | --- |
| Auth por `x-project-id` | Aceito para hml/demo; vira o item **26** antes de produção real | `docs/09-crud-projeto/variance_report.md` |
| Storage S3 não ligado | Local em hml; vira o item **27** | idem |
| E2E precisa exercitar a UI real no hml | Corrigido no item 9g; **regra permanente** para toda feature | memória `e2e-precisa-exercitar-de-verdade` |
| Bateria automatizada vem por último | Regra de método (cap. 22 do livro), não débito | `CLAUDE.md` › Método de trabalho |
| API pública serve **rascunho**, não versão publicada | Entrou com a fatia 1 do item 25, **antes** do item 24 (precedência do plano). Não abrir para cliente real antes do 24 | `docs/13-loop-sdui/variance_report.md` VR-13-01 |
| Chave publicável sem rotação nem rate limit | Gerada por projeto; rotação vai com o item 26, rate limit com o 25 | idem, VR-13-03/04 |
