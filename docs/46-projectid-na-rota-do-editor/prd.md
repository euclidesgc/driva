# PRD — O `projectId` entra na rota do editor

> **Item 46 do roadmap** · bug pré-existente, achado na validação do item 24 contra hml em
> 2026-08-17 · doc irmã: [`specs.md`](specs.md)
>
> **Decisões A1–A4 travadas pelo humano em 2026-08-17** (`specs.md` › _Decisões do humano_):
> **A1›A** (`/projects/:projectId/contents/:id/edit`), **A2›B** (rota legada **removida**,
> cai no `onException` padrão, home **sem** aviso dedicado — decisão **contra** a
> recomendação do PM/tech-lead, que era avisar), **A3›B** (a tela de falha diz o escopo que
> tentou), **A4›A** (correção pontual no padrão da D18). Pronto para o `tech-lead` escrever
> o `plan.md`.

---

## Problema

A URL do editor não diz de que projeto é o conteúdo que ela abre. O escopo do tenant mora
num singleton em memória (`ProjectScope`) que só é preenchido quando o usuário **caminha**
pelo app a partir da tela do projeto. Todo recarregamento perde esse estado e o app volta ao
projeto `default`.

O efeito, para quem usa: **apertar F5 no editor de qualquer projeto que não seja o `default`
troca a tela por "Conteúdo não encontrado."** — e o conteúdo está lá, intacto. O mesmo vale
para abrir a URL numa aba nova, num link salvo, ou num link mandado para outra pessoa.

Três agravantes que fazem disso mais que um incômodo:

1. **A mensagem mente.** Quem lê "não encontrado" conclui que perdeu trabalho. O caminho de
   recuperação (voltar à home, entrar no projeto, achar o conteúdo de novo) só é descoberto
   por tentativa.
2. **A URL do editor não é compartilhável.** Mandar "olha essa tela" para alguém entrega uma
   tela de erro — a menos que o destinatário, por acaso, esteja no projeto certo.
3. **É a última rota do app com esse defeito.** `/projects/:id` e `/preview/:projectId/:id`
   já carregam a identidade na URL; a do editor ficou para trás e foi registrada como dívida
   na D24 do item 41.

**Por que isto piora sozinho, sem ninguém tocar no código.** Hoje o estrago é limitado
porque o fallback (`DEFAULT_PROJECT_ID`) aponta para um projeto que **existe** em dev e em
hml — o `default`. Os quatro flavors carregam o mesmo valor, **produção incluída**
(`apps/driva_editor/config/prod.json`). No dia em que houver projetos de clientes reais
(item 26) e não existir um projeto chamado `default` naquela instalação, **todo reload do
editor vira 404 — para todo mundo, sempre**, e não só para quem saiu do projeto padrão. O
custo de consertar é o mesmo agora e depois; o custo de conviver, não. _(Achado lateral, não
é decisão deste item: "projeto padrão compilado no binário" é um conceito que deixa de fazer
sentido quando a auth chegar — anotar para o item 26.)_

---

## Resultado esperado

**A URL do editor passa a bastar.** Quem tem o link tem o conteúdo — no reload, na aba nova,
na máquina do colega, no driver de E2E. E quando o link **não** resolve, a tela diz a
verdade sobre o que tentou, em vez de acusar sumiço.

Quatro frases que descrevem o "pronto":

- **F5 no editor recarrega o mesmo conteúdo**, em qualquer projeto, não só no `default`.
- **Um link do editor colado numa aba nova abre o conteúdo certo**, sem passar pela tela do
  projeto antes.
- **O link "ver no celular" gerado depois de um reload aponta para o projeto certo.** Hoje
  ele sai `/preview/default/<id>` **sem nenhum sinal de erro** — é o modo silencioso do
  mesmo bug, e o que a evidência atual não cobre.
- **Quando o link aponta para um par projeto+conteúdo que não existe**, a tela nomeia o
  projeto em que procurou e oferece a saída — nunca a mensagem seca de sumiço.

---

## Recorte proposto — duas fases + a bateria

O recorte é do produto; o desenho técnico das fases é do `plan.md` (tech-lead).

### F1 — A rota carrega o projeto

A rota do editor passa a ser `/projects/:projectId/contents/:id/edit`. O `pageBuilder`
valida os dois path params, **carimba o `ProjectScope` antes de montar o cubit** (padrão
D18, o mesmo do `preview_page.dart`) e segue. Os dois pontos de navegação da tela do projeto
passam o `projectId` que já têm em mãos.

**O link antigo (`/contents/:id/edit`) não é registrado no formato novo** — decisão A2›B.
Não há tela de aviso: a URL antiga simplesmente não casa com nenhuma rota, e o
`onException` já existente manda para a home de projetos, calada. Nenhum código novo aqui —
é o comportamento padrão do router para rota desconhecida.

### F2 — A tela de falha para de mentir

`NotFoundFailure` na carga do editor deixa de virar "Conteúdo não encontrado." e passa a
dizer em que projeto procurou, com o nome do projeto (que a rota nova já entrega pelo
`projectFuture`) e um caminho de volta. Decisão A3›B — esta fase entra.

### F3 — Bateria automatizada

Por último, depois do E2E atestado — regra do cap. 22.

> **O tech-lead estimou 1 fase / 1 PR** para F1+F1b+F2: em produção o diff é
> `editor_routes.dart`, o `pageBuilder` de `editor_page.dart`, duas linhas em
> `project_detail_page.dart` e a tela do link antigo. O resto é script de E2E, CHANGELOG e
> docs. A F3 (bateria) segue depois do E2E atestado, como sempre. **Recorte final no
> `plan.md`.**

---

## Caminho feliz

1. O dev abre a home, entra no projeto **Acme** (não é o `default`), clica num conteúdo.
2. O editor abre em `/projects/<acme>/contents/<id>/edit`. A URL mostra os dois ids.
3. Ele edita, salva, e aperta **F5** — por hábito, ou porque o app pediu.
4. O app reinicia, lê o `projectId` do path, carimba o escopo, e **o mesmo conteúdo volta**,
   com o breadcrumb do projeto Acme correto.
5. Ele copia a URL e manda para outra pessoa. Ela abre numa máquina que nunca viu o driva:
   **cai direto no editor daquele conteúdo**, sem passar pela tela do projeto.
6. Ainda na aba recarregada, ele abre "ver no celular": o QR e o link copiável apontam para
   `/preview/<projeto Acme>/<id>` — e o celular abre o conteúdo, não um 404.

---

## Exceções e casos de borda

| Situação | Comportamento esperado |
|---|---|
| `projectId` ausente ou vazio no path | Tela de rota inválida (o padrão que `InvalidPreviewScreen`/`InvalidContentScreen` já estabelecem), não tela em branco |
| `contentId` ausente ou vazio | Idem — é o comportamento de hoje, preservado |
| `projectId` existe, `contentId` não existe naquele projeto | 404 → mensagem da F2, **nomeando o projeto** |
| `projectId` de um projeto que o usuário não tem (ou não existe) | 404 do backend, mesma mensagem — o editor **não** afirma qual dos dois motivos foi (o backend não distingue de propósito, e não vai passar a distinguir) |
| Conteúdo existe, mas em **outro** projeto que não o da URL | 404, tratado como o caso acima. Não existe "achamos em outro projeto" — seria vazamento cross-tenant |
| Projeto **arquivado** na URL | Comportamento do item 9e, herdado sem mudança. Se divergir, é achado novo, vai para `variance_report.md` |
| Link antigo `/contents/:id/edit` | Home de projetos, sem aviso dedicado — `onException` padrão (A2›B) |
| Duas abas abertas em **projetos diferentes** | Cada uma carimba o `ProjectScope` no seu `pageBuilder`, mas o singleton é **um só por aba** (cada aba é um app) — não há interferência entre abas. **Dentro da mesma aba**, alternar entre conteúdos de projetos diferentes pelo histórico do navegador re-executa o `pageBuilder` e recarimba: é o mesmo mecanismo do `/preview`, e o E2E deve exercitá-lo (item 9 do DoD) |
| Botão "voltar" do navegador saindo do editor | Volta para a tela do projeto, como hoje. Se a rota nova for aninhada, isso precisa continuar verdadeiro |
| `/preview/:projectId/:id` | **Não muda nada.** Já está certo — é o precedente |
| App rodando com `USE_FAKE_DATA: true` | O bug **não aparece** (`FakeContentsStore` não é escopado por projeto). Não é caso de borda do produto: é armadilha de validação, e por isso todo aceite roda em hml |

---

## Analytics

**Nenhum evento novo.** Mantém a decisão vigente registrada em `ANALYTICS.md`: o editor não
envia analytics enquanto não houver usuários além do time. Quando entrar (junto do item 25),
"editor aberto por deep link" é candidato natural — e este item cria a condição de medi-lo,
porque a URL passa a carregar o projeto.

---

## Erros monitorados

Nenhuma `Failure` nova. O que muda é **como uma delas é apresentada**:

| Failure | Antes | Depois |
|---|---|---|
| `NotFoundFailure` (conteúdo, com o projeto resolvido) | "Conteúdo não encontrado." | "Não encontramos este conteúdo no projeto _<Nome>_." + caminho de volta |
| `NotFoundFailure` (o **projeto** da URL não resolve) | hoje nem chega a acontecer: o `projectFuture` resolve o `default` e mente em silêncio | "Este link aponta para um projeto que não existe." — separável **sem request novo**, porque `GET /v1/projects/:id` não é escopado pelo header |
| Demais (`Network`, `Validation`, `Unexpected`) | inalteradas | inalteradas |

`ERROR_LOGS.md` ganha uma linha na tabela de `NotFoundFailure` registrando que a UX passou a
citar o escopo — a semântica da falha (404 = inexistente **ou** de outro tenant) não muda.

---

## Critérios de aceite

### F1 — a rota carrega o projeto

1. `EditorRoutes.editor` é `/projects/:projectId/contents/:id/edit`; o nome da rota
   (`editorName`) não muda, então quem navega por nome continua compilando — mas passa a
   precisar dos dois `pathParameters`.
2. O `pageBuilder` escreve `getIt<ProjectScope>().projectId` **antes** de montar o
   `BlocProvider` (padrão D18) — verificável por teste de widget que monta a rota e inspeciona
   o header da primeira requisição, não por leitura de código.
3. As duas navegações de `project_detail_page.dart` (abrir conteúdo, criar conteúdo) passam o
   `projectId`.
4. **O link "ver no celular" (`canvas_area.dart`) gerado após um reload frio aponta para o
   projeto da URL**, não para o `default`. É o único critério que cobre o modo silencioso.
5. O `projectId` **não** vira parâmetro obrigatório de `EditorPage` — continua vindo do
   cubit (cerca da D19; do contrário caem quatro testes que montam a página sem DI).
6. `flutter analyze` verde e a suíte existente passando.

### F1 — o link antigo

7. Abrir `/contents/<id>/edit` leva à home de projetos **sem aviso dedicado** (via
   `onException` padrão) — não à tela do editor, não a uma tela em branco.

### F2 — a falha diz a verdade

8. Abrir `/projects/<projeto-A>/contents/<id-de-outro-projeto>/edit` mostra mensagem que
   **nomeia o projeto A** e oferece o caminho de volta.
9. Abrir a rota com um `projectId` **inexistente** mostra mensagem **diferente** da anterior
   ("o link aponta para um projeto que não existe") — a distinção que o `projectFuture` já
   permite sem request novo.
10. Nenhuma das duas afirma nem sugere que o conteúdo existe em outro projeto.
11. As duas telas de falha são **visualmente distintas** entre si, da tela de carregamento e
    da de conteúdo vazio — provável por print.

### F3 — bateria

12. Teste de widget: `pageBuilder` da rota nova carimba o escopo e dispara a carga com o
    `x-project-id` do path (o teste que prova o item 2).
13. Teste de widget: path param faltando → tela de rota inválida.
14. Teste de widget: `NotFoundFailure` com projeto resolvido → mensagem cita o nome do
    projeto; projeto não resolvido → a outra mensagem.
15. Teste de navegação: os dois `goNamed` de `project_detail_page.dart` produzem a URL nova.
16. Regressão: os quatro testes que montam `EditorPage` direto
    (`editor_page_layout_controller_test.dart`, `editor_perf_test.dart`,
    `page/editor_workspace_test.dart`, `widgets/canvas_panel_golden_test.dart`) continuam
    passando **sem DI** — a propriedade que a D19 protegeu e que o `VR-16-02` mostrou ser
    frágil.

---

## E2E — o que a prova precisa mostrar (entra no DoD do `plan.md`)

Em **homologação**, com UI real, num projeto que **não** é o `default` (a lição do item 9g:
`localhost` não vale, e o `default` é justamente o caso que esconde o bug):

| # | Passo | O que o print prova |
|---|---|---|
| 1 | Abrir um conteúdo pela tela do projeto | URL com os dois ids |
| 2 | **F5** | o mesmo conteúdo de volta, breadcrumb do projeto certo |
| 3 | Copiar a URL, colar em **aba anônima** | abre o conteúdo, sem passar pela tela do projeto |
| 4 | Ainda na aba recarregada, abrir **"ver no celular"** | o link/QR aponta para `/preview/<projeto certo>/<id>` — hoje sairia `default` **sem erro nenhum na tela** |
| 5 | Após o mesmo reload, conferir o **breadcrumb** e o botão "Voltar para o projeto" | levam ao projeto certo |
| 6 | Trocar o `:projectId` da URL por outro projeto válido | mensagem citando **aquele** projeto, não "não encontrado" seco |
| 7 | Trocar o `:projectId` por um que não existe | mensagem **diferente** da do passo 6 |
| 8 | Abrir uma URL no formato antigo | home, sem aviso dedicado (`onException` padrão) |
| 9 | Ida e volta pelo histórico entre conteúdos de **dois projetos** na mesma aba | os dois carregam certo — o escopo é recarimbado a cada rota |

Os passos **6, 7 e 8 são os modos de falha** e precisam produzir telas **visualmente
distintas** entre si e da tela de sucesso. O passo **4 é o modo silencioso** — o único que a
evidência de hoje não cobriria, e onde o bug se esconde. Evidência em
`docs/46-projectid-na-rota-do-editor/evidencias/rodada_01/`, atestada pelo dev humano.

---

## Riscos

| # | Risco | Mitigação |
|---|---|---|
| R1 | Algum ponto de navegação para o editor passa despercebido e quebra em runtime (go_router falha por path param faltando) | O `editorName` continua o mesmo, então o compilador **não** ajuda — e **nenhum teste da suíte hoje referencia a rota do editor** (varredura por `EditorRoutes`/`editorName`/`/contents/` em `apps/driva_editor/test/`: zero ocorrências), então a suíte verde **não** é prova aqui. A varredura manual é item obrigatório da revisão de fase, e o item 12 dos critérios de aceite existe justamente para fechar esse buraco |
| R2 | **Cinco** scripts de E2E ativos (02, 04, 15, 16, 24) montam a URL antiga na unha e passariam a cair na home em vez de abrir o editor | Não se reescreve evidência histórica; o script que for **re-executado** se atualiza. No do item 24, os `goto(projectUrl())` de aquecimento do escopo (linhas 339/378/508) ficam obsoletos e devem sair — eles eram o contorno do bug. Registrar no CHANGELOG que a URL do editor mudou |
| R2b | Validar com `USE_FAKE_DATA: true` e concluir que está tudo bem — o `FakeContentsStore` não é escopado por projeto e **esconde o bug** | O aceite roda em hml, num projeto ≠ `default`. Escrito no roteiro, não só na cabeça de quem executa |
| R2c | O `projectId` virar parâmetro obrigatório de `EditorPage` "porque ficou mais limpo" e derrubar quatro testes (o tropeço do `VR-16-02`) | Cerca explícita no `plan.md` e item 5 dos critérios de aceite |
| R3 | Docs passam a mentir sobre a rota: `docs/plans/20-componente-construtor/plan.md:38` afirma "a rota **não muda**", `docs/plans/26-auth-multi-tenant/plan.md:228` cita a rota antiga no fluxo de login, e `docs/08-.../plan.md`, `docs/17-ergonomia-editor/plan.md`, `docs/24-.../final_report.md` e o `CHANGELOG.md` a citam | Varredura de texto no fechamento do item. Planos de gaveta e docs vivas se corrigem; **evidências de rodadas passadas, não** |
| R4 | A rota aninhada muda o comportamento do "voltar" ou do breadcrumb sem ninguém perceber | Passo 6 do E2E + o teste do breadcrumb existente (`app_shell_breadcrumb_bar_test.dart`) |
| R5 | O singleton mutável continua vivo e a próxima rota repete o erro (A4›A é correção pontual) | Regra escrita no `plan.md` e cobrada na revisão: **rota que depende de escopo de projeto carrega o `projectId` no path**. Débito estrutural apontado para o item 26 |

---

## Decisões travadas

### Do humano (2026-08-17)

- **A1** — Rota `/projects/:projectId/contents/:id/edit` (recomendação seguida).
- **A2** — Link antigo remove a rota, cai no `onException` padrão, home sem aviso dedicado
  (**contra** a recomendação, que era avisar antes de mandar para a home).
- **A3** — Inclui a tela de falha, separando projeto inexistente de conteúdo inexistente no
  projeto (recomendação seguida).
- **A4** — Correção pontual, 1 PR, padrão D18 (recomendação seguida); matar o singleton
  `ProjectScope` registrado como débito vivo para o item 26.

Detalhamento completo em `specs.md` › _Decisões do humano que sustentam esta spec_.

### Herdadas, não reabertas

- **D3/D18 (item 41)** — `projectId` no path + `pageBuilder` carimbando o `ProjectScope`
  antes do primeiro request. Padrão validado em produção pelo `/preview`.
- **D24 (item 41)** — o deep link frio do editor era limitação conhecida e declarada fora
  daquele escopo. Este item a paga; não é regressão de ninguém.
- **404 indistinguível entre tenants** — controle de segurança do backend. Nada neste item
  pede que ele mude.
- **`x-project-id` como mecanismo de tenant** — débito aceito até o item **26**.
