# PRD — Download do APK de teste ao lado do QR do preview

> **Item 51 do roadmap** (Marco 6) · pedido do humano em 2026-08-20 · discovery em
> 2026-08-22 · doc irmã: [`specs.md`](specs.md)
>
> **Escopo travado pelo dono (E1):** o APK é de **demonstração fixa** — saída **(c)** do item
> 51. Deep link / config em runtime (saída **(a)**) está **fora**, e vira item próprio.
>
> ✅ **PRD fechado.** A0–A8 todas decididas (`specs.md` › _Decisões pendentes do humano_) — A1
> e A6 confirmadas pelo dono, as demais técnicas fechadas pelo tech-manager na recomendação.
> O recorte de fases abaixo é o recorte final. Pronto para o `tech-lead` escrever o
> `plan.md`.

---

## Problema

A janela **"Ver no celular"** do editor oferece um caminho só: abrir o preview **no
navegador** do aparelho. Isso prova que o spec renderiza — não prova que o **app** renderiza.

A diferença não é teórica; ela já custou um item. Em 2026-08-17 o dev gerou um APK à mão,
abriu um conteúdo publicado num Android físico e viu o app desenhando **casca própria** que
não vinha do spec (`docs/roadmap.md:70`). Nada disso aparecia no preview web. O aprendizado
que ficou: **o navegador e o app não são a mesma prova**, e o único jeito de ver o segundo é
instalando o segundo.

Hoje instalar o app custa: clonar o repositório, ter Flutter e o SDK do Android, descobrir a
chave publicável na API, rodar `tool/run_demo.sh MODE=apk`, esperar o build, achar o
`.apk` em `build/app/outputs/`, mandar para o aparelho. É um caminho de desenvolvedor com o
repositório na mão — e mesmo para ele, é ritual demais para uma conferência de trinta
segundos.

**A parte incômoda do problema:** a distância entre "montei a tela" e "vi a tela no app" é
grande o bastante para que a conferência simplesmente não aconteça. E quando ela não
acontece, defeitos de renderização em aparelho viajam até alguém tropeçar neles — que foi
exatamente o que aconteceu.

---

## Resultado esperado

**Quem está no editor consegue pôr o app de demonstração num aparelho Android sem sair da
janela de preview** — um toque no QR para ver a tela no navegador, um clique no botão para
baixar o app e ver como o renderer se comporta de verdade.

E, junto disso, **a tela é honesta sobre o que está entregando**. O escopo travado (E1) faz o
app baixado abrir um conteúdo de demonstração fixo, **não** o conteúdo que está aberto no
editor. Um botão que não disser isso engana — o próprio roadmap classificou esta saída como a
que _"engana mais do que ajuda"_ justamente por esse risco.

Quatro frases que descrevem o "pronto":

- **O botão está onde o usuário já está** — na janela "Ver no celular", junto do QR, sem
  navegação nova.
- **O link aponta para um build recente e automático** — ninguém builda à mão, ninguém
  atualiza URL à mão.
- **A tela diz o que o app baixado mostra** (demonstração fixa), **diz o que fazer no
  iPhone** (o preview instalável, que já existe) e **diz o que o Android vai pedir** (fonte
  desconhecida; e, se A4›S1, desinstalar a versão anterior).
- **Ambiente sem APK publicado não mostra botão nenhum** — nem botão morto, nem erro.

---

## Recorte proposto — duas fases

_Confirmado: A1›H1 (GitHub Releases), A2›K1, A3›G1, A5›E1, A8›A._

### F1 — A CI publica o APK

Job novo no `.github/workflows/ci.yml`, separado do job `android` de hoje (que continua
`--debug`, como cancela de PR). Roda **só** em `push` para `develop`, builda
`flutter build apk --release --target lib/main_hml.dart` com a chave descoberta na API, e
publica no tag fixo `demo-app-latest` (pre-release), sobrescrevendo o asset.

`permissions: contents: write` **no job**, nunca no topo do workflow — a invariante
declarada no `ci.yml` continua valendo para todos os outros.

**Testes desta fase:** a prova é o próprio job verde e o asset baixável. Não há código Dart
novo a testar; o que se documenta é o comando e o gatilho.

### F2 — O editor oferece o download

`DEMO_APK_URL` entra no `AppConfig` do editor e nos `config/<env>.json`; desce do
`pageBuilder` até o diálogo pelo **mesmo caminho do `imageUrlResolver`**
(`editor_page.dart` → `center_area.dart` → `canvas_area.dart` → `PreviewShareDialog`).
Widget novo, arquivo novo, irmão do `PreviewInstallHint`: botão + aviso, todo por token.

**Testes desta fase, escritos junto dela:**

- widget: URL preenchida ⇒ botão aparece com o rótulo aprovado na A6;
- widget: URL **vazia** ⇒ nenhum botão, nenhum espaço morto;
- widget: o aviso "app de demonstração" e a linha do iOS estão presentes sempre que o botão
  estiver;
- widget: clicar aciona o `NewTabLauncher` com a URL de config (injetável, como já é feito
  para "Abrir em nova aba");
- **navegação:** a árvore montada **a partir da rota** entrega a URL até o diálogo. Este é o
  teste que não pode faltar — `demoApkUrl` é mais um parâmetro opcional descendo quatro
  níveis, e **parâmetro opcional nulo que ninguém liga na ponta já produziu três defeitos
  silenciosos neste repositório**, todos invisíveis para o `analyze` e para a suíte;
- os três tamanhos de tela do `preview_share_dialog_test.dart` continuam passando com o
  diálogo mais alto.

---

## Caminho feliz

1. O usuário está no editor, com um conteúdo aberto.
2. Aciona **"Ver no celular"**. O diálogo abre: QR, link copiável, dica de instalar o
   preview.
3. Abaixo disso, um bloco novo: **botão de download do app de demonstração** e o aviso do que
   ele é.
4. Clica. O navegador baixa o `.apk` (nova aba/atalho de download; nada muda na tela do
   editor).
5. Manda o arquivo para o Android, autoriza a instalação de fonte desconhecida, instala.
6. Abre o app: ele carrega o **conteúdo de demonstração** contra a API de homologação e o
   desenha com o `sdui_flutter` — o mesmo renderer que o editor usa.
7. O usuário compara o que vê no app com o que montou no editor.

---

## Exceções e casos de borda

| # | Situação | Comportamento esperado |
|---|---|---|
| B1 | **Nenhum APK publicado ainda** (primeiro deploy desta feature) | `DEMO_APK_URL` vazio no config ⇒ **o botão não é renderizado**. Sem botão desabilitado, sem espaço em branco, sem erro |
| B2 | URL configurada, mas o **asset sumiu ou a publicação falhou** | O clique abre a página 404 do GitHub em outra aba. **O editor não trava nem muda de estado** — é o limite aceito da A5›E1, e o preço de não fazer request em runtime |
| B3 | **Editor de produção** | `config/prod.json` com `DEMO_APK_URL` vazio (A8›A) ⇒ sem botão. O editor de produção não oferece um app que fala com homologação |
| B4 | **Usuário em iPhone/Mac** | O bloco continua visível, e **diz** que para iOS o caminho é o preview instalável logo acima. Não some, não promete o que não entrega |
| B5 | **Já existe uma versão do app instalada** e a assinatura mudou | O Android recusa com "app não instalado" e **não explica**. Quem explica é o aviso do editor (A4›S1). Se A4 fechar em S2, esta linha some |
| B6 | **hml fora do ar na hora do build** (A2›K1) | O job de publicação falha em `develop`, **em vermelho e visível**. O asset anterior continua no ar. Nenhum PR é bloqueado |
| B7 | **Conteúdo com `root` nulo / página vazia** no editor | Irrelevante para este item: o app baixado não abre esse conteúdo. É a consequência direta de E1, e é o que o aviso da A6 declara |
| B8 | **`USE_FAKE_DATA: true`** (editor rodando com fakes) | O botão segue a config, não os fakes. Se `DEMO_APK_URL` estiver preenchido no `fake.json`, ele aparece — e o download é real. Decidir no plano se o `fake.json` recebe URL ou vazio; **recomendo vazio** |
| B9 | O usuário espera que o app baixado abra **o conteúdo do preview** | É a expectativa que E1 quebra de propósito. O aviso da A6 é o único mecanismo que a atende — não há código que resolva isso dentro deste escopo |

---

## Analytics

**Não há infraestrutura de analytics no projeto.** Varredura por `analytics`/`telemetry` em
`apps/driva_editor/lib` e `backend/src`: zero ocorrências. Este item **não** cria uma —
seria fundar uma capacidade inteira de carona numa feature de um botão.

Fica registrado o que deveria ser instrumentado quando a capacidade existir, porque é a
pergunta que decide o futuro deste item:

| Evento | Propriedades | Para que serve |
|---|---|---|
| `preview_dialog_opened` | `projectId`, `contentId` | denominador de tudo abaixo |
| `demo_apk_download_clicked` | `projectId`, `environment` | **a métrica que decide se a saída (a) vale o investimento**: uso alto + reclamação de "abriu outro conteúdo" é o sinal de que o deep link precisa entrar |
| `demo_apk_button_hidden` | `environment` | quantas vezes um ambiente ficou sem APK publicado — mede a confiabilidade do job da F1 |

Enquanto não houver analytics, o sinal de uso é **relato do dono**. Registrado como tal, não
disfarçado de medição.

---

## Erros monitorados

| Onde | Falha | Tratamento |
|---|---|---|
| Editor | Nenhuma nova. Com A5›E1 o botão é um `String` de config e um `NewTabLauncher` — **não há request, não há `Failure`, não há estado de erro a modelar** | Se a A5 fechar em **E2** (consultar a API do GitHub), aí sim entra `Failure` tipada, tratamento no cubit e teste de falha de rede — e a fase cresce |
| Editor | Config ausente/vazia | Não é erro: é o caso B1, e o comportamento é não renderizar |
| CI (F1) | Build de release quebrado (AOT, tree-shake de ícones) | Job vermelho em `develop`. **Ganho colateral:** o `ci.yml` declara hoje, por escrito, que AOT e tree-shake são buraco não coberto — este job passa a cobri-los |
| CI (F1) | Chave publicável não resolvida (hml fora, projeto renomeado) | O script já valida o prefixo `pk_` e falha alto. **Nunca** publicar APK com placeholder: foi assim que nasceu a "vitrine vazia" do item 25 |
| CI (F1) | Upload do asset falha | Job vermelho; o asset anterior permanece. Publicação não é atômica com o merge, e isso é aceito |
| Backend | Nenhum. Com A1›H1 **o backend não é tocado** | Se A1 fechar em H3, entra endpoint novo com gate obrigatório do CISO |

---

## Critérios de aceite

### F1 — a CI publica

1. Um `push` em `develop` produz um asset `.apk` no tag `demo-app-latest`, e a URL
   `https://github.com/euclidesgc/driva/releases/download/demo-app-latest/<arquivo>.apk`
   baixa **sem autenticação** (verificável por `curl -sIL` devolvendo `200`).
2. A release está marcada **pre-release** — o selo _Latest_ da página de Releases continua
   com a release SemVer do produto.
3. `permissions: contents: write` aparece **só** no job novo; o topo do workflow segue
   `contents: read`.
4. O job **não** roda em `pull_request` — nenhum PR, de fork ou não, sobrescreve o asset.
5. O APK publicado carrega a chave real: instalado, ele **mostra conteúdo**, não vitrine
   vazia. (Prova de campo — ver abaixo.)
6. O job `android` de hoje continua `--debug` e continua sendo a cancela de PR; o tempo do PR
   não aumenta.

### F2 — o editor oferece

7. Com `DEMO_APK_URL` preenchida, o diálogo "Ver no celular" mostra o botão com o rótulo
   aprovado na A6, **abaixo** do QR e do link.
8. Com `DEMO_APK_URL` **vazia**, não há botão nem espaço reservado — a árvore é idêntica à de
   hoje.
9. O aviso de que o app é **demonstração fixa** aparece **sempre que o botão aparecer**, e
   nunca separado dele.
10. A linha sobre iOS está presente.
11. Clicar aciona o `NewTabLauncher` com exatamente a URL da config (injetável no teste).
12. Nenhuma cor, medida, raio ou tipografia literal — `scripts/gates_guard.sh` verde.
13. O widget novo é **classe própria em arquivo próprio** (Gates 1 e 3), com `Semantics`
    no controle.
14. Um teste monta a árvore **a partir da rota** e prova que a URL chega ao diálogo — não
    basta testar o widget isolado.
15. Os três tamanhos do `preview_share_dialog_test.dart` seguem passando.
16. `dart format`, `flutter analyze` e a suíte completa verdes.

---

## Validações de campo pendentes

_(E2E está suspenso desde 2026-08-20 — a régua de conclusão é a pirâmide automatizada. O que
só o hardware prova entra aqui e vai para `docs/roadmap.md` › **Validações de campo
pendentes** no fechamento do item, com o dono executando quando tiver o aparelho.)_

Este item tem uma quantidade **incomum** de prova que nenhum teste alcança — praticamente
tudo o que ele entrega vive fora do Dart:

| # | O que só o aparelho/navegador real prova |
|---|---|
| V1 | O `.apk` publicado **instala** num Android físico, partindo do link do editor |
| V2 | Instalado, o app **mostra o conteúdo de demonstração** — a prova de que a chave da A2 foi resolvida certo, e não o placeholder |
| V3 | O build de **release** (AOT + tree-shake de ícones) não produz "tofu" nem ícone faltando — o modo de falha que já aconteceu no bundle web do editor |
| V4 | **Reinstalar por cima** de uma versão anterior: se a assinatura mudou, confirma que o aviso da A4›S1 descreve o que o Android de fato faz |
| V5 | O clique no botão **baixa** o arquivo no Chrome/Firefox do desktop (`Content-Disposition`), em vez de abrir uma aba com lixo binário |

**V2 e V4 são os que mais importam** — são exatamente os dois modos de falha que já morderam
este repositório antes (a vitrine vazia do item 25, e o `INTERNET` ausente que só apareceu num
aparelho).

---

## Riscos

| # | Risco | Mitigação |
|---|---|---|
| R1 | **O botão engana**: o usuário instala esperando ver o conteúdo que estava editando e vê outro | É o risco central da decisão E1, e **nenhum código o resolve** — só o texto da A6, colado ao botão e nunca separável dele. Critério de aceite 9 |
| R2 | `demoApkUrl` desce quatro níveis como parâmetro **opcional** e alguém esquece de ligar um elo — o botão some sem ninguém notar, `analyze` verde e suíte verde | Precedente literal e recorrente no repositório (`GetContentCheckpointUseCase`, `imageUrlResolver`). Critério 14: o teste monta a árvore **a partir da rota** |
| R3 | O APK publicado fica **stale** e ninguém percebe | A3›G1 (publica em todo `push` em `develop`) é a mitigação. Se a resposta for G2 ou G3, o risco volta e a UI precisa mostrar data/versão — o que empurra a A5 para E2 |
| R4 | A CI ganha `contents: write` e vira superfície de escrita no repositório | Permissão **por job**, job restrito a `push` em `develop`, sem `secrets.*`. Fork de PR não o alcança. Item de gate do CISO |
| R5 | Instalar APK de fonte desconhecida é passo manual que o usuário não conhece | Texto da A6, item 4 |
| R6 | O job da F1 depende de `GET /v1/projects` **sem autenticação** (A2›K1) — débito do item 26 | Registrar no CISO como dependência conhecida: quando a auth chegar, este job é um dos call sites que quebram |
| R7 | Cada build muda a assinatura e a atualização quebra (A4›S1) | Assumido, e dito na tela. Débito: keystore real (A4›S2) quando houver distribuição de verdade |
| R8 | O item 51 do roadmap fecha como se **toda** a intenção original tivesse sido entregue, e a saída (a) se perde | A0 resolve: item 51 fecha explicitamente na saída **(c)**, e a saída **(a)** nasce como item novo, com o texto do débito |
| R9 | O `main_prod.dart`/`config/prod.json` do app de demonstração colidiam com esta fase | **Resolvido antes do plan.md**: foram commitados e viraram PR próprio (`feature/demo-app-prod-build`, #219). A F2 mexe nos `config/<env>.json` do **editor** (não do app); a F1 usa `main_hml.dart`. Sem sobreposição real |

---

## Decisões travadas

### Do dono, antes do discovery

- **E1** — APK de **demonstração fixa** (saída **(c)** do item 51). O app baixado não abre o
  conteúdo em edição. Deep link e config em runtime (saída **(a)**) ficam fora e viram item
  próprio.

### Fechadas

A0, A1 e A6 confirmadas pelo dono; A2, A3, A4, A5, A7, A8 fechadas pelo tech-manager na
recomendação. Detalhe de cada uma: `specs.md` › _Decisões pendentes do humano_. Nada
pendente — pronto para o `plan.md`.

### Herdadas, não reabertas

- **Item 25** — a receita de build release existe (`apps/driva_demo_app/tool/run_demo.sh`
  `MODE=apk`) e a chave real **não** se versiona.
- **Item 41 / D31** — o preview web é instalável como PWA; é o caminho do iOS, e continua
  sendo.
- **Item 51** — a chave é compile-time; distribuição é metade do trabalho; iOS fica fora por
  plataforma, não por escopo.
- **`publishableKey` é pública por natureza** — só lê conteúdo publicado, nunca escreve
  (desde a fatia 1 do item 25).
- **E2E suspenso** (2026-08-20) — a prova para no unitário + widget; o que só o aparelho
  mostra vai para _Validações de campo pendentes_.
