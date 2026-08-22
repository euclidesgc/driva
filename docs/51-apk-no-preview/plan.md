# Plano — Baixar o APK de teste na janela de preview

> **Item 51 do roadmap** (Marco 6) · saída **(c)**, APK de demonstração fixa · docs irmãs:
> [`prd.md`](prd.md) e [`specs.md`](specs.md).
>
> **Duas fases, duas PRs.** F1 põe a CI publicando o `.apk`; F2 põe o editor oferecendo o
> download. **E2E não entra** — suspenso no repositório desde 2026-08-20 (`CLAUDE.md` ›
> _Método de trabalho_): a prova para no unitário + widget, mais o próprio job de CI verde.

---

## Estado

| Quando | O que |
|---|---|
| 2026-08-20 | O dono pede o botão e trava o escopo (**E1**: APK de demonstração fixa) |
| 2026-08-22 | Discovery fechado — `specs.md` com A0–A8 decididas, `prd.md` aprovado |
| 2026-08-22 | **Este plano.** Nenhuma linha de código escrita ainda |

Duas condições da árvore, conferidas ao escrever este plano:

- **`docs/51-apk-no-preview/` está untracked** — `prd.md` e `specs.md` ainda não foram
  commitados. Entram na primeira PR desta feature.
- **A PR #219 (`feature/demo-app-prod-build`) está aberta**, não mergeada, e é onde nasceram
  `apps/driva_demo_app/lib/main_prod.dart` e `apps/driva_demo_app/config/prod.json`. Este
  plano **não toca** nenhum dos dois: a F1 builda `lib/main_hml.dart` e a F2 mexe nos
  `config/<env>.json` do **editor**, não do app. Sem sobreposição (R9 do PRD, confirmado no
  código).

---

## 1. Objetivo e recorte

Quem está no editor abre **"Ver no celular"** e, além do QR e do link, encontra um bloco com o
botão **`Baixar APK de teste`** e o aviso de que o app baixado mostra **um conteúdo de
demonstração fixo**, não o que está aberto no editor. Ambiente sem APK publicado não mostra
bloco nenhum.

Fora: deep link, config em runtime do app, APK por projeto, iOS, keystore de release, endpoint
novo no backend, analytics. Todos declarados no `specs.md` › _Fora de escopo_ e reiterados na
§9 deste plano.

---

## 2. O terreno, medido no código (2026-08-22)

### 2.1 A superfície de UI já existe, e o bloco tem um irmão para imitar

`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart`
é um `AlertDialog` com `SizedBox(width: AppSpacing.s320)` → `SingleChildScrollView` →
`Column`, e o último filho dessa `Column` é `const PreviewInstallHint()`. O bloco novo entra
**depois dele**, com o mesmo desenho (`Container` + `primaryTint` + `AppRadii.r8` +
`AppSpacing.s12`) — nenhum token novo é necessário, e o `EditorColors` já tem tudo
(`primaryTint`, `inkSecondary`, `border`, `panelAlt`, `warning`).

O conteúdo já rola (`SingleChildScrollView`), então o diálogo mais alto não estoura em
900×500 — mas isso precisa de prova, e é a razão do `ensureVisible` na T2.4.

### 2.2 O fio da config tem **cinco** elos, não três

O `prd.md` descreve o caminho como `editor_page.dart → center_area.dart → canvas_area.dart →
PreviewShareDialog`. O código tem dois elos a mais, e um deles com **duas** chamadas:

```text
EditorPage.pageBuilder            editor_page.dart:114   getIt<AppConfig>()
  └ EditorPage (campo)            editor_page.dart:25/173
     └ EditorWorkspaceHost        editor_workspace_host.dart:27/75
        └ EditorWorkspace         editor_workspace.dart:24/66 e :70   ← duas chamadas de CenterArea
           └ CenterArea           center_area.dart:9/45
              └ CanvasArea        canvas_area.dart:18/129
                 └ PreviewShareDialog
```

As duas chamadas de `CenterArea` em `editor_workspace.dart` (linha 66 no modo tela cheia,
linha 70 dentro do `ResizableSplitView`) são exatamente o formato do defeito que o **R2** do
PRD descreve: ligar uma e esquecer a outra deixa o botão sumindo só em tela cheia, com
`analyze` verde. A D7 mata isso no compilador.

### 2.3 O editor implantado **não lê** `config/<env>.json` — o furo que o PRD não viu

`apps/driva_editor/Dockerfile:16-33` não usa `--dart-define-from-file`. Ele declara
`ARG API_BASE_URL` / `ARG DEFAULT_PROJECT_ID` (Build Variables do Coolify) e passa
`--dart-define` um a um, sempre com `--target lib/main_prod.dart` — hml e prod são **o mesmo
Dockerfile**, separados só pelo valor das Build Variables.

Consequência direta: **preencher `config/hml.json` não faz o botão aparecer em homologação.**
Sem `ARG DEMO_APK_URL` no Dockerfile e sem a Build Variable no recurso de hml do Coolify, o
`String.fromEnvironment('DEMO_APK_URL')` do bundle implantado resolve para `''` e o botão
nunca nasce — o mesmo caso B1, mas por engano, e sem sinal nenhum.

O lado bom: é assim que a **A8›A** se implementa de verdade no mundo implantado. O recurso de
hml recebe a Build Variable; o de produção não recebe, e por isso não mostra o botão. Nada de
lógica condicional no Dart.

### 2.4 A CI de hoje e as duas invariantes que ela declara por escrito

`.github/workflows/ci.yml`: `permissions: contents: read` no topo, com o comentário das linhas
28-31 justificando ("Nenhum job usa `secrets.*` nem escreve no repositório…"); jobs `flutter`,
`android` (`needs: flutter`, `--debug`, `main_dev.dart`) e `backend`; `env.FLUTTER_VERSION:
"3.44.9"` no topo, consumido por mais de um job.

O job novo quebra metade da primeira invariante (passa a escrever no repositório, via
Releases) e **não** quebra a outra: nenhum segredo guardado entra na conta (D4). O comentário
precisa ser **reescrito**, não apagado — um comentário que passa a mentir é pior que nenhum.

### 2.5 A receita de APK já existe, e a CI não pode virar a terceira cópia dela

`apps/driva_demo_app/tool/run_demo.sh` em `MODE=apk` já faz, nesta ordem: recusa API em
`http://`; descobre a chave em `GET $API/v1/projects` (filtrando por `PROJECT_TITLE` quando
dado); valida o prefixo `pk_`; builda `flutter build apk --release --target "$TARGET"` com
`API_BASE_URL` e `PUBLISHABLE_KEY`. O `.vscode/scripts/resolve-demo-key.sh` é a **segunda**
implementação da mesma descoberta. Uma terceira, escrita em YAML dentro do workflow, seria a
que dessincroniza calada (D2).

O que falta no script para a CI: o `DEFAULT_SLUG`. Hoje ele não é passado, e o app cai no
default `'home'` (`apps/driva_demo_app/lib/core/config/app_config.dart:22`). Se o conteúdo de
demonstração da hml não estiver publicado nesse slug, o APK compila, instala e mostra
**vitrine vazia** — o defeito do item 25 outra vez, invisível para toda a pirâmide (D3).

### 2.6 O `NewTabLauncher` não é injetável hoje

`preview_share_dialog.dart:139` chama `const NewTabLauncher().open(url)` direto, e o stub de
VM (`new_tab_launcher_stub.dart:10-12`) **lança `UnsupportedError`** quando chamado. Ou seja:
hoje nenhum teste consegue clicar em "Abrir em nova aba" sem explodir, e o critério 11 do PRD
("injetável no teste") descreve algo que ainda não existe. A D10 cria a injeção.

---

## 3. Decisões travadas

### D1 — O asset se chama `driva-demo-hml.apk`, e a URL é o tag fixo — **[tech-lead, fecha o `<arquivo>.apk` do critério 1]**

O `flutter build apk` produz `app-release.apk`, nome genérico demais para um asset público. O
job renomeia antes de publicar. A URL que o editor carrega, literal e inteira:

```text
https://github.com/euclidesgc/driva/releases/download/demo-app-latest/driva-demo-hml.apk
```

**Nunca** a forma `releases/latest/download/…`: no GitFlow deste repositório `latest` resolve
para a release SemVer do produto, que não tem este asset (aviso herdado do `specs.md` › A1).
O `-hml` no nome é a marca do ambiente — quando existir um APK de produção (A8›B), ele nasce
com outro nome ao lado, sem renomear o que já circula.

### D2 — O job de CI **chama** `run_demo.sh MODE=apk`; não reimplementa a descoberta de chave — **[tech-lead, A2›K1]**

A lógica de "descubra a chave no `GET /v1/projects` e valide o `pk_`" já existe em dois
lugares. O workflow chama o script existente com `MODE=apk TARGET=lib/main_hml.dart`. Um
`grep` por `v1/projects` no `ci.yml` tem de sair vazio — é o critério que impede a terceira
cópia.

### D3 — Antes de publicar, o par (chave, slug) é verificado contra a API pública — **[tech-lead, além do PRD]**

O `run_demo.sh` ganha, **só no `MODE=apk`** e **antes** do `flutter build`, uma consulta a
`$API/v1/public/contents/$SLUG` com o header `x-driva-key: $key`; resposta diferente de `200`
aborta o script.

Por quê, em uma frase: **a "vitrine vazia" é um dos dois modos de falha que este item mais
teme (V2 do PRD), e seis linhas de shell a transformam de validação de campo em cancela de
máquina.** O que continua sendo de campo é o _desenho_ da tela no aparelho — que o conteúdo
existe e a chave o alcança passa a ser provado antes de qualquer publicação. Ganho colateral:
protege também o build local, que hoje falha do mesmo jeito e só se descobre no aparelho.

Junto vem `SLUG="${SLUG:-home}"` passado como `--dart-define=DEFAULT_SLUG` — o valor deixa de
ser implícito e passa a ser dito em voz alta nos dois modos do script.

### D4 — `GH_TOKEN: ${{ github.token }}`, e o comentário do `permissions:` é reescrito — **[tech-lead, R4]**

`permissions: contents: write` mora **dentro** do job novo; o topo do workflow segue
`contents: read`. O passo de publicação usa `${{ github.token }}` — o mesmo valor de
`secrets.GITHUB_TOKEN`, escrito na forma que mantém `grep -n "secrets\." .github/workflows/ci.yml`
vazio e deixa claro que **nenhum segredo guardado** entrou no repositório.

O comentário das linhas 28-31 passa a dizer a verdade nova: nenhum job usa segredo guardado; o
job de publicação escreve no repositório com o token automático, e o escopo de escrita vive só
nele.

### D5 — A tag não se move; a nota da release carrega o commit e a data — **[tech-lead]**

`gh release create` cria o tag no commit da primeira execução e ele fica lá. Recriar o tag a
cada publicação abriria uma janela em que a URL responde 404 e tiraria a garantia de "o asset
anterior continua no ar" (B6). Em vez disso, cada execução dá `gh release edit --notes` com o
SHA e a data UTC — a página de Releases passa a ser o lugar onde se confere a frescura do
link, já que a A5›E1 tirou versão e data da tela do editor.

### D6 — `concurrency` no job, com `cancel-in-progress: true` — **[tech-lead]**

Dois merges em `develop` em sequência curta disparam duas publicações sobre o mesmo tag; sem
cancela, a mais antiga pode terminar por último e sobrescrever a mais nova com um binário
velho — falha silenciosa, porque as duas saem verdes.

### D7 — `demoApkUrl` é `String` (nunca `String?`), **required** nos quatro elos internos e com default `''` só nas duas pontas — **[tech-lead, mata o R2 no compilador]**

- `EditorWorkspaceHost`, `EditorWorkspace`, `CenterArea` e `CanvasArea` recebem
  `required final String demoApkUrl`. **Sem default**: esquecer de ligar qualquer elo — ou
  ligar só uma das duas chamadas de `CenterArea` da §2.2 — vira **erro de compilação**, não um
  botão que some.
- `EditorPage` recebe `this.demoApkUrl = ''`, pelo mesmo motivo de `contentId` e
  `layoutController` (D19 do item 41): `editor_perf_test.dart`,
  `canvas_panel_golden_test.dart` e `editor_workspace_test.dart` montam a página sem DI.
- `PreviewShareDialog` recebe `this.demoApkUrl = ''` — vazio é um **estado legítimo** ali (é o
  caso B1), não um esquecimento.

Custo assumido: três arquivos de teste que hoje montam `const CanvasArea()` /
`EditorWorkspace(...)` passam a informar `demoApkUrl: ''`. É barato, e é o preço de trocar um
defeito silencioso por um erro do analisador.

**A alternativa rejeitada:** instalar um `InheritedWidget` de escopo (como
`EditorLayoutScope`, a D7 do item 16, que existe justamente para não somar passageiro ao
repasse por construtor). Rejeitada porque o `imageUrlResolver` ao lado já usa o repasse, o
valor é um `String` consumido em **um** ponto-folha, e um soquete novo seria mais maquinário
do que o problema pede. Com `required` nos elos internos, o argumento que motivou o soquete
(elo esquecido em silêncio) deixa de se aplicar.

### D8 — Os textos aprovados na A6 são `Text` simples, com a string exata — **[tech-lead]**

Nada de `Text.rich`/`TextSpan` (que quebraria `find.text` e tornaria o aceite inverificável).
Os quatro textos, literais:

| Papel | String exata |
|---|---|
| Rótulo do botão | `Baixar APK de teste` |
| Aviso obrigatório | `Este é um app de demonstração com um conteúdo fixo — não mostra o que você está editando agora.` |
| iOS | `No iPhone, use o preview instalável acima.` |
| Android (fonte desconhecida + reinstalação) | `O Android vai pedir permissão para instalar de fonte desconhecida. Se já tiver uma versão instalada, desinstale antes de instalar esta.` |

O aviso e o botão vivem no **mesmo widget** — não há como renderizar um sem o outro, que é o
único mecanismo contra o R1.

### D9 — Quem decide "sem URL, sem bloco" é o diálogo, num lugar só — **[tech-lead, B1 / critério 8]**

`PreviewShareDialog` monta `if (demoApkUrl.isNotEmpty) ...[SizedBox(height: AppSpacing.s16),
DemoApkDownloadBlock(...)]`. O espaçador entra no mesmo `if` — é o que garante "nem botão
morto, nem espaço em branco". O bloco em si não tem estado vazio: recebe uma URL e desenha.

### D10 — O `NewTabLauncher` vira parâmetro do diálogo, e o botão de hoje passa a usá-lo — **[tech-lead, critério 11]**

`PreviewShareDialog` e `DemoApkDownloadBlock` ganham `this.launcher = const NewTabLauncher()`.
"Abrir em nova aba" deixa de instanciar o launcher inline e passa a usar o campo — sem isso, o
parâmetro existiria só para o teste, e o botão antigo continuaria intestável (§2.6). Teste
injeta uma subclasse que grava a URL recebida.

### D11 — `dev` e `hml` recebem a URL; `fake` e `prod` ficam vazios — **[herdada, A8›A + B8]**

`apps/driva_editor/config/dev.json` e `config/hml.json` levam a URL da D1.
`config/prod.json` e `config/fake.json` levam `""`. O `fake.json` fica vazio de propósito: a
suíte de fakes não deve oferecer um download real (recomendação do B8). No mundo implantado,
quem decide é a Build Variable do Coolify (§2.3).

### D12 — O APK **não** ganha `--no-tree-shake-icons` — **[tech-lead]**

O `apps/driva_editor/Dockerfile` usa a flag por um motivo que é só de web: a fonte de ícones
vira subset diferente a cada build e o navegador serve a versão em cache. Num APK a fonte
viaja dentro do binário, então não há cache cruzado. Como nada no app, no renderer ou no
kernel constrói `IconData` dinamicamente (o próprio comentário do `ci.yml` registra isso), a
flag só somaria peso. O "tofu" em release continua sendo **V3**, validação de campo.

### D13 — Nenhuma linha de E2E, em nenhuma fase — **[dono, 2026-08-20]**

Nem script (`e2e_hml.sh`/`e2e_drive.mjs`), nem `e2e_roteiro.md`. A prova para no unitário +
widget, mais o job de CI verde. O que só o aparelho mostra é V1–V5 do PRD e vai para
`docs/roadmap.md` › _Validações de campo pendentes_ no fechamento (T2.5).

---

## 4. Fases e tarefas

Precedência: **F1 → F2** no merge. Em despacho, `T1.1`/`T1.2` e `T2.1`/`T2.2` são frentes
disjuntas e podem correr ao mesmo tempo, em worktrees separadas.

```text
F1 CI publica  ──────────────► (merge)
   T1.1 script ─► T1.2 workflow
   T1.3 docs (paralela a T1.2)
                                 F2 editor oferece ──► (merge, empilhada sobre F1)
                                    T2.1 config+deploy ─┐
                                    T2.2 widget novo   ─┴─► T2.3 fio ─► T2.4 bateria
                                                                        T2.5 docs (paralela a T2.4)
```

---

### F1 — A CI publica o APK · **[0-dep]** · **1 PR** · **[`especialista-infra`]** · ⚠️ **gate do CISO obrigatório** (R4, R6, A7)

Ao fim da F1, um `push` em `develop` produz um `.apk` baixável sem autenticação na URL da D1.
Nenhum PR é afetado: o job novo não roda em `pull_request`, e o job `android` de hoje continua
sendo a cancela de PR, em `--debug`.

#### T1.1 — `run_demo.sh` aprende o slug e verifica o conteúdo antes de buildar **[paralela: sim — arquivo próprio, disjunto de T2.1/T2.2]**

Em `apps/driva_demo_app/tool/run_demo.sh`:

1. `SLUG="${SLUG:-home}"` junto das outras variáveis do topo, e
   `--dart-define=DEFAULT_SLUG="$SLUG"` nas **duas** invocações do `flutter` (`run` e `apk`) —
   o valor deixa de ser um default implícito do Dart.
2. Só em `MODE=apk`, **depois** da validação do prefixo `pk_` e **antes** do
   `flutter build apk`: consulta `"$API/v1/public/contents/$SLUG"` com o header
   `x-driva-key: $key` e aborta com mensagem no stderr quando o código HTTP não for `200`. A
   mensagem nomeia o slug e o código, porque é ela que alguém vai ler às 23h quando o job
   ficar vermelho.
3. O cabeçalho de uso no topo do arquivo ganha a linha do `SLUG`.

A chave continua aparecendo truncada no log (`${key:0:14}…`) — nada de imprimir o valor
inteiro, mesmo sendo chave publicável.

**DoD**
- `apps/driva_demo_app/tool/run_demo.sh` declara `SLUG="${SLUG:-home}"` e
  `grep -n "DEFAULT_SLUG" apps/driva_demo_app/tool/run_demo.sh` retorna **duas** linhas, uma
  no ramo `run` e outra no ramo `apk` do `case`.
- No mesmo arquivo, a linha que consulta `/v1/public/contents/` com o header `x-driva-key`
  aparece **antes** da linha `flutter build apk --release` na ordem literal do arquivo, e o
  bloco em volta dela termina em `exit 1` quando o código HTTP não é `200`.
- Essa verificação está dentro do ramo `apk` (ou sob um `if [[ "$MODE" == apk ]]`): o modo
  `run` não faz a consulta.
- `bash -n apps/driva_demo_app/tool/run_demo.sh` sai com código 0.
- `grep -n "\$key" apps/driva_demo_app/tool/run_demo.sh` não mostra nenhuma linha que imprima
  a variável inteira em stdout/stderr — a única impressão continua sendo a truncada
  `${key:0:14}…`.

#### T1.2 — O job `publish-demo-apk` no `.github/workflows/ci.yml` **[paralela: não — dep. T1.1, que é quem ele chama]**

Job novo, no fim do arquivo, com:

- `name: APK de demonstração — publica no tag demo-app-latest`, `needs: flutter` (não publica
  binário de um commit cujo Dart está vermelho), `runs-on: ubuntu-latest`;
- `if: github.event_name == 'push' && github.ref == 'refs/heads/develop'`;
- `permissions:` com `contents: write` **dentro do job**;
- `concurrency:` com `group` fixo e `cancel-in-progress: true` (D6);
- passos: `actions/checkout@v4` → `actions/setup-java@v4` (temurin 17, `cache: gradle`, o
  mesmo `cache-dependency-path` do job `android`) → `subosito/flutter-action@v2` com
  `${{ env.FLUTTER_VERSION }}` → `dart pub get` (workspace) → build pelo script → renomear →
  publicar.

O build e a publicação, literalmente:

```yaml
      - name: Build APK release (chave e conteúdo resolvidos na API de homologação)
        working-directory: apps/driva_demo_app
        env:
          MODE: apk
          TARGET: lib/main_hml.dart
          API: https://api-hml.driva.duckdns.org
          PROJECT_TITLE: ${{ vars.DEMO_PROJECT_TITLE }}
          SLUG: ${{ vars.DEMO_SLUG }}
        run: |
          ./tool/run_demo.sh
          mv build/app/outputs/flutter-apk/app-release.apk \
             build/app/outputs/flutter-apk/driva-demo-hml.apk

      - name: Publica no tag fixo demo-app-latest
        working-directory: apps/driva_demo_app
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh release view demo-app-latest >/dev/null 2>&1 || \
            gh release create demo-app-latest \
              --target "$GITHUB_SHA" --prerelease \
              --title 'App de demonstração (homologação)' \
              --notes 'Asset rolante: sempre o último build de develop.'
          gh release upload demo-app-latest \
            build/app/outputs/flutter-apk/driva-demo-hml.apk --clobber
          gh release edit demo-app-latest \
            --notes "Build de homologação · commit $GITHUB_SHA · $(date -u '+%Y-%m-%d %H:%M UTC')"
```

`SLUG` e `PROJECT_TITLE` vazios são o caso normal: o script cai em `home` e no primeiro
projeto. As duas variáveis existem para o dia em que a hml tiver mais de um projeto ou o
conteúdo de demonstração mudar de slug — e nenhuma delas é secret.

Junto, no mesmo commit: reescrever o comentário do bloco `permissions:` do topo (linhas 28-31)
para a verdade nova (D4).

**DoD**
- `.github/workflows/ci.yml` tem um job cujo `if` é exatamente
  `github.event_name == 'push' && github.ref == 'refs/heads/develop'` e que declara
  `permissions:` → `contents: write` **dentro** do job; o `permissions:` do topo do arquivo
  continua `contents: read` e é a única ocorrência fora de um job.
- `grep -n "secrets\." .github/workflows/ci.yml` não retorna nenhuma linha, e o passo de
  publicação define `GH_TOKEN: ${{ github.token }}`.
- `grep -n "v1/projects" .github/workflows/ci.yml` não retorna nenhuma linha: a descoberta da
  chave acontece dentro de `apps/driva_demo_app/tool/run_demo.sh`, chamado com
  `MODE=apk` e `TARGET=lib/main_hml.dart`.
- O job novo declara `concurrency:` com `cancel-in-progress: true`, e o arquivo é YAML válido:
  `python3 -c "import yaml;yaml.safe_load(open('.github/workflows/ci.yml'))"` sai com código 0.
- O job `android` continua com `flutter build apk --debug --target lib/main_dev.dart`, sem
  bloco `permissions:` próprio, e nenhum outro job ganhou permissão de escrita.
- O comentário acima do `permissions:` do topo não afirma mais que nenhum job escreve no
  repositório: ele nomeia o job de publicação, diz que a escrita é escopada a ele e que o token
  é o automático do Actions, não um segredo guardado.

#### T1.3 — CHANGELOG e roadmap da F1 **[paralela: sim — `CHANGELOG.md`/`docs/`, disjuntos do workflow]** *(textual — não lança supervisor)*

`CHANGELOG.md` › `Unreleased`: a CI passa a publicar o APK de demonstração de homologação no
tag `demo-app-latest`, com a URL da D1. `docs/roadmap.md`: item 51 vira `[-]` (em andamento).
E os dois arquivos de discovery (`prd.md`, `specs.md`), hoje untracked, entram versionados
nesta PR junto deste plano.

**DoD**
- `CHANGELOG.md` tem, sob `## [Unreleased]`, uma linha citando o tag `demo-app-latest` e o
  nome do asset `driva-demo-hml.apk`.
- `docs/roadmap.md` marca o item 51 como `[-]`.
- `git status --short docs/51-apk-no-preview/` não mostra nenhum arquivo untracked (`??`).

---

### F2 — O editor oferece o download · **[dep. F1 no merge; T2.1/T2.2 podem começar antes]** · **1 PR empilhada** · **[`especialista-infra` na T2.1 · `especialista-apresentacao` nas T2.2-T2.4]**

#### T2.1 — `DEMO_APK_URL` do `AppConfig` ao Coolify **[paralela: sim — nenhum arquivo em comum com T2.2; pode correr junto da F1]** · **[`especialista-infra`]**

Quatro frentes do mesmo fio de configuração:

1. `apps/driva_editor/lib/core/config/app_config.dart`: campo `final String demoApkUrl`,
   `required` no construtor principal (como todos os outros campos da classe), lido em
   `AppConfig.fromEnvironment` por `const String.fromEnvironment('DEMO_APK_URL')` — sem
   `defaultValue`, porque o default de `String.fromEnvironment` já é `''`, que é o estado
   "sem botão". Entra também em `props`.
2. Os quatro `apps/driva_editor/config/*.json` (D11): `dev.json` e `hml.json` com a URL da D1;
   `prod.json` e `fake.json` com `""`.
3. `apps/driva_editor/Dockerfile`: `ARG DEMO_APK_URL` junto dos outros ARGs e
   `--dart-define=DEMO_APK_URL=${DEMO_APK_URL}` na linha do `flutter build web` (§2.3 — sem
   isto o botão nunca aparece em homologação, por mais correto que o resto esteja).
4. `docs/deploy/coolify.md` § _3. Frontend (Flutter Web)_, item 4: a Build Variable
   `DEMO_APK_URL` entra na lista, com o valor para hml e a instrução explícita de **deixar
   ausente/vazia em produção**.

Os dois arquivos de teste que hoje constroem `AppConfig(...)` à mão passam a informar o campo
novo — o `required` é justamente o que os obriga a decidir.

**DoD**
- `apps/driva_editor/lib/core/config/app_config.dart` declara `final String demoApkUrl;`, o
  construtor principal o exige com `required`, `AppConfig.fromEnvironment` o preenche com
  `const String.fromEnvironment('DEMO_APK_URL')` e `demoApkUrl` aparece na lista `props`.
- `grep -n DEMO_APK_URL apps/driva_editor/config/dev.json apps/driva_editor/config/hml.json`
  mostra em ambos o valor
  `https://github.com/euclidesgc/driva/releases/download/demo-app-latest/driva-demo-hml.apk`;
  nos arquivos `apps/driva_editor/config/prod.json` e `apps/driva_editor/config/fake.json` a
  mesma chave existe com o valor `""`.
- `apps/driva_editor/Dockerfile` declara `ARG DEMO_APK_URL` e a linha do `flutter build web`
  inclui `--dart-define=DEMO_APK_URL=${DEMO_APK_URL}`.
- `docs/deploy/coolify.md`, na seção do frontend Flutter Web, lista `DEMO_APK_URL` entre as
  Build Variables, dizendo o valor de hml e que em produção ela fica vazia/ausente.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai
  verde — o que só acontece depois de os arquivos de teste que constroem `AppConfig(...)`
  informarem o campo novo.

#### T2.2 — O widget `DemoApkDownloadBlock` **[paralela: sim — arquivo novo + teste novo, disjuntos de T2.1]** · **[`especialista-apresentacao`]**

Arquivo novo
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block.dart`,
irmão de `preview_install_hint.dart` e com o mesmo desenho: `Container` com
`EdgeInsets.all(AppSpacing.s12)`, `BorderRadius.circular(AppRadii.r8)` e fundo
`EditorColors.primaryTint`, texto em `AppTypography.sm` sobre `inkSecondary`. **Nenhum literal
de cor, medida, raio ou tipografia** — Gate 4.

Conteúdo, de cima para baixo: o aviso obrigatório, a linha do iOS, a linha do Android (os três
textos exatos da D8, cada um num `Text` próprio) e, por último, um
`OutlinedButton.icon` com `Icon(Icons.android)` e `Text('Baixar APK de teste')`, dentro de um
`Tooltip` que diga o destino. O controle expõe nome acessível `Baixar APK de teste` — cor não
é sinal de nada aqui, e o rótulo é textual.

Construtor: `const DemoApkDownloadBlock({required this.url, this.launcher = const
NewTabLauncher(), super.key})`. `onPressed` chama `launcher.open(url)`.

O teste do bloco isolado nasce junto, em
`apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block_test.dart`,
com uma subclasse local de `NewTabLauncher` que grava a URL recebida em vez de abrir aba (o
stub de VM lança `UnsupportedError`, então sem a injeção o toque explode).

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block.dart`
  existe, declara **uma** classe (`DemoApkDownloadBlock extends StatelessWidget`), não contém
  nenhum método que retorne `Widget` além de `build`, e seu construtor é
  `const DemoApkDownloadBlock({required this.url, this.launcher = const NewTabLauncher(), super.key})`.
- O arquivo contém, como strings literais e cada uma num `Text` simples (nunca `TextSpan`):
  `Baixar APK de teste`;
  `Este é um app de demonstração com um conteúdo fixo — não mostra o que você está editando agora.`;
  `No iPhone, use o preview instalável acima.`;
  `O Android vai pedir permissão para instalar de fonte desconhecida. Se já tiver uma versão instalada, desinstale antes de instalar esta.`
- `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block_test.dart`
  prova, com uma subclasse de `NewTabLauncher` injetada pelo construtor, que tocar o
  `OutlinedButton` de texto `Baixar APK de teste` chama `open` **uma vez** com exatamente a URL
  passada ao widget; e prova, com `tester.ensureSemantics()`, que existe um nó de semântica com
  o rótulo `Baixar APK de teste`.
- `bash scripts/gates_guard.sh` (a partir da raiz do repositório) sai com código 0.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai
  verde, e `flutter test -r compact test/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block_test.dart`
  passa.

#### T2.3 — O fio: do `pageBuilder` ao diálogo, cinco elos **[paralela: não — dep. T2.1 (o campo do `AppConfig`) e T2.2 (o widget)]** · **[`especialista-apresentacao`]**

Na ordem do fio (§2.2), cada elo ganha `demoApkUrl` seguindo a D7 —
`required` nos quatro internos, default `''` nas duas pontas:

| Arquivo | O que muda |
|---|---|
| `.../editor/editor_page.dart` | campo `this.demoApkUrl = ''`; `pageBuilder` passa `getIt<AppConfig>().demoApkUrl`; `build` repassa a `EditorWorkspaceHost` |
| `.../editor/page/editor_workspace_host.dart` | `required final String demoApkUrl`, repassado a `EditorWorkspace` |
| `.../editor/page/editor_workspace.dart` | `required final String demoApkUrl`, repassado às **duas** chamadas de `CenterArea` |
| `.../editor/page/center_area.dart` | `required final String demoApkUrl`, repassado a `CanvasArea` |
| `.../editor/page/canvas_area.dart` | `required final String demoApkUrl`; `_openPreviewDialog` o passa ao `PreviewShareDialog` |
| `.../editor/widgets/canvas/preview_share_dialog.dart` | `this.demoApkUrl = ''` e `this.launcher = const NewTabLauncher()`; renderiza o bloco sob a regra da D9; "Abrir em nova aba" passa a usar o campo `launcher` |

`getIt` continua sendo tocado **só** no `pageBuilder` — nenhum outro arquivo desta tabela pode
importar `injection.dart`. Os arquivos de teste que montam esses widgets sem DI passam a
informar `demoApkUrl: ''`.

**DoD**
- `grep -n "demoApkUrl" apps/driva_editor/lib/modules/editor_module/presentation/editor/page/editor_workspace_host.dart apps/driva_editor/lib/modules/editor_module/presentation/editor/page/editor_workspace.dart apps/driva_editor/lib/modules/editor_module/presentation/editor/page/center_area.dart apps/driva_editor/lib/modules/editor_module/presentation/editor/page/canvas_area.dart`
  mostra, em cada um dos quatro arquivos, a declaração `required final String demoApkUrl` (ou
  `required this.demoApkUrl` no construtor) — **nenhum** deles com valor default e **nenhum**
  deles com tipo `String?`.
- Em `apps/driva_editor/lib/modules/editor_module/presentation/editor/page/editor_workspace.dart`
  as **duas** construções de `CenterArea(` recebem `demoApkUrl:` — a do ramo de tela cheia e a
  do `ResizableSplitView`.
- Em `apps/driva_editor/lib/modules/editor_module/presentation/editor/editor_page.dart`, a
  única leitura nova do container é `getIt<AppConfig>().demoApkUrl`, dentro do corpo de
  `static Widget pageBuilder`; `grep -n "getIt<" ` nesse arquivo não mostra ocorrência fora
  desse método.
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart`
  monta `DemoApkDownloadBlock` **e** o espaçador que o precede dentro de um mesmo
  `if (demoApkUrl.isNotEmpty)`, e a chamada de "Abrir em nova aba" usa o campo `launcher` em
  vez de `const NewTabLauncher()`.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai
  verde e `bash scripts/gates_guard.sh` (da raiz) sai com código 0.

#### T2.4 — A bateria: da rota até o botão **[paralela: não — dep. T2.3]** · **[`especialista-apresentacao`]**

Dois arquivos, um novo e um que cresce.

**Novo** —
`apps/driva_editor/test/modules/editor_module/editor_demo_apk_wiring_test.dart`, copiando o
harness de
`apps/driva_editor/test/modules/editor_module/editor_checkpoint_wiring_test.dart`: `getIt` com
repositórios fake, `GoRouter` com `initialLocation: '/projects/<id>/contents/<id>/edit'` e
`EditorRoutes.route`, superfície 1600×1200. É **o** teste que o critério 14 exige: prova que a
URL sai do `AppConfig` no `pageBuilder` e chega ao diálogo pela árvore real, não por um
harness que já monta os widgets soltos com o valor na mão.

**Cresce** —
`apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog_test.dart`:
os três tamanhos de hoje continuam (agora construindo o diálogo com `demoApkUrl` vazio, o que
prova de quebra o caso B1), mais os casos com URL preenchida.

**DoD**
- `apps/driva_editor/test/modules/editor_module/editor_demo_apk_wiring_test.dart` existe,
  monta a árvore a partir de um `GoRouter` com `EditorRoutes.route` e um `AppConfig` registrado
  no `getIt` com `demoApkUrl: 'https://exemplo.test/driva-demo-hml.apk'`, abre a janela pelo
  controle de tooltip `Ver no celular` e prova que o `PreviewShareDialog` montado tem
  `demoApkUrl` igual a essa string **e** que o texto `Baixar APK de teste` está na tela.
- O mesmo arquivo tem um segundo caso com `demoApkUrl: ''` no `AppConfig` registrado, provando
  `find.byType(DemoApkDownloadBlock)` → `findsNothing` e `find.text('Baixar APK de teste')` →
  `findsNothing` depois de abrir a janela.
- `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog_test.dart`
  continua exercitando os três tamanhos `Size(1280, 900)`, `Size(1024, 600)` e `Size(900, 500)`
  e ganha casos que, com `demoApkUrl` preenchida, encontram na tela as quatro strings da tarefa
  (rótulo do botão, aviso de demonstração, linha do iPhone e linha do Android) e, em
  `Size(900, 500)`, chamam `tester.ensureVisible` no botão sem que o teste lance.
- Um dos casos do diálogo injeta uma subclasse de `NewTabLauncher` e prova que o toque no botão
  chama `open` com a mesma URL passada em `demoApkUrl`.
- `cd apps/driva_editor && flutter test -r compact` passa inteiro, e `dart test -r compact
  packages/sdui_core` (da raiz) segue verde.

#### T2.5 — Fechamento: docs vivas, roadmap e o débito da saída (a) **[paralela: sim — `docs/` e `CHANGELOG.md` não têm arquivo em comum com `apps/driva_editor/test/` da T2.4]** *(textual — não lança supervisor)*

- `docs/51-apk-no-preview/final_report.md`: o que foi entregue, **como operar o asset** (tag
  fixo, nome do arquivo, que o tag não se move, como republicar à mão por
  `gh release upload --clobber`, as duas variáveis opcionais de repositório) e a lista V1–V5
  como risco assumido.
- `CHANGELOG.md` › `Unreleased`: o botão de download na janela "Ver no celular".
- `docs/roadmap.md`: item 51 vira `[x]` **declarando que fechou na saída (c)**; nasce um item
  novo para a saída **(a)** (config em runtime + deep link no app, o que faria o APK abrir o
  conteúdo em edição), posicionado por dependência; e a seção _Validações de campo pendentes_
  ganha a linha do item 51 com V1–V5.

**DoD**
- `docs/51-apk-no-preview/final_report.md` existe, cita a URL
  `https://github.com/euclidesgc/driva/releases/download/demo-app-latest/driva-demo-hml.apk` e
  descreve como republicar o asset à mão.
- `CHANGELOG.md`, sob `## [Unreleased]`, tem uma linha sobre o botão de download do app de
  demonstração na janela de preview.
- `docs/roadmap.md` marca o item 51 como `[x]` com a menção explícita à saída (c), e contém um
  item novo, distinto do 51, descrevendo config em runtime + deep link (a saída (a)).
- A tabela da seção `## Validações de campo pendentes` de `docs/roadmap.md` ganhou uma linha
  cuja coluna de origem é o item **51** e que nomeia: instalar o APK num Android físico, o app
  mostrar o conteúdo de demonstração, o build de release sem "tofu"/ícone faltando, a
  reinstalação por cima de versão anterior e o download pelo navegador do desktop.

---

## 5. Ordem de PRs, gates e paralelismo de despacho

1. **PR 1 (F1)** — base `develop`. Toca `.github/workflows/ci.yml`,
   `apps/driva_demo_app/tool/run_demo.sh`, `CHANGELOG.md`, `docs/roadmap.md` e a pasta
   `docs/51-apk-no-preview/` inteira. **Gate do CISO obrigatório**: `contents: write` na CI
   (R4), a dependência do `GET /v1/projects` sem autenticação (R6, débito do item 26) e a
   exposição pública do APK com `pk_` embarcado (A7). O parecer vive em
   `docs/51-apk-no-preview/ciso_review.md`.
2. **PR 2 (F2)** — **empilhada sobre a F1**, nunca solta contra `develop`
   (`docs/GITFLOW.md` § 6). Toca só `apps/driva_editor/**`, `docs/deploy/coolify.md`,
   `CHANGELOG.md` e `docs/roadmap.md`.

**Despacho:** `T1.1`, `T2.1` e `T2.2` são três frentes sem arquivo em comum e podem sair ao
mesmo tempo, em worktrees. `T1.3` corre junto de `T1.2`; `T2.5` corre junto de `T2.4`. As
sequenciais estão marcadas com a dependência real, e não devem ser forçadas a paralelo.

**Supervisor cego (`supervisor-dod`)** em T1.1, T1.2, T2.1, T2.2, T2.3 e T2.4 — todas mudam
comportamento. T1.3 e T2.5 são textuais e entram no lote do QA da fase.

---

## 6. Riscos e proteções

| Risco | Proteção neste plano |
|---|---|
| **R1** — o botão engana: o usuário instala esperando ver o conteúdo que editava | Aviso e botão no **mesmo widget** (D8/D9); DoD da T2.2 cobra a string exata, e a da T2.4 cobra que ela aparece sempre que o botão aparece |
| **R2** — um elo do fio fica sem ligar e o botão some em silêncio | `required` nos quatro elos internos (D7): vira erro de compilação. Mais o teste que monta a árvore **a partir da rota** (T2.4) |
| **Só uma das duas chamadas de `CenterArea` é ligada** — botão some só em tela cheia | Mesma D7 + linha de DoD dedicada às duas construções em `editor_workspace.dart` |
| **O botão nunca aparece em hml**, com F1 e F2 verdes | §2.3: `ARG DEMO_APK_URL` no `apps/driva_editor/Dockerfile` + Build Variable no Coolify, cobrados na T2.1 e listados na §7 |
| **R3** — o APK fica stale | A3›G1: publica em todo `push` em `develop`; a nota da release carrega o SHA (D5) |
| **R4** — a CI ganha superfície de escrita | Permissão por job, `if` restrito a `push` em `develop`, token automático (D4), gate do CISO |
| **Vitrine vazia** (chave certa, slug sem conteúdo publicado) | D3: o script verifica o par (chave, slug) contra `/v1/public/contents/<slug>` **antes** do build |
| **Publicação fora de ordem** em dois merges seguidos | `concurrency` + `cancel-in-progress` (D6) |
| **R7** — assinatura de debug quebra a atualização | Assumido (A4›S1); dito na tela, terceiro texto da D8. Débito: keystore real |
| O diálogo mais alto estoura em janela pequena | `SingleChildScrollView` já existe; DoD da T2.4 exige `ensureVisible` em 900×500 |
| **B2** — o asset some e o clique cai em 404 | Limite aceito da A5›E1; nada a implementar, registrado no `final_report.md` |

---

## 7. O que ainda precisa do humano

1. **Build Variable `DEMO_APK_URL` no recurso do editor de homologação, no Coolify**, com a
   URL da D1, seguida de rebuild. **Sem isso o botão não aparece em hml**, mesmo com as duas
   PRs mergeadas (§2.3). No recurso de produção, **não** criar a variável.
2. **Opcional:** variáveis de repositório `DEMO_PROJECT_TITLE` e `DEMO_SLUG` no GitHub, se o
   projeto de demonstração da hml não for o primeiro da lista de `GET /v1/projects` ou se o
   conteúdo publicado não estiver no slug `home`. Vazias, o comportamento default vale.
3. **Nenhum segredo novo** a cadastrar — nem no GitHub, nem no Coolify.
4. **V1–V5** (PRD › _Validações de campo pendentes_) quando tiver o aparelho na mão. Não
   bloqueiam o fechamento do item.

---

## 8. Divergências e precisões em relação ao PRD

Nenhuma decisão do PRD foi alterada. Três precisões, porque o PRD descreve o código com menos
resolução do que ele tem — e uma adição:

| # | O PRD diz | O código mostra | O que este plano faz |
|---|---|---|---|
| P1 | O fio passa por `editor_page.dart → center_area.dart → canvas_area.dart` | Passa também por `editor_workspace_host.dart` e `editor_workspace.dart`, e `CenterArea` é construído **duas** vezes | D7 e T2.3 tratam os cinco elos e as duas construções |
| P2 | O `NewTabLauncher` é "injetável, como já é feito para Abrir em nova aba" | Não é: `preview_share_dialog.dart:139` instancia inline, e o stub de VM lança | D10 cria a injeção e converte o botão antigo |
| P3 | `DEMO_APK_URL` entra "no `AppConfig` e nos `config/<env>.json`" | O editor implantado não lê esses arquivos — lê ARGs do Dockerfile | T2.1 inclui o `Dockerfile` e a doc do Coolify |
| P4 | (não menciona) | O APK pode compilar com chave válida e slug sem conteúdo publicado | **Adição** da D3: verificação do par (chave, slug) antes de publicar |

P4 é adição de proteção, não mudança de contrato — não abre entrada no `variance_report.md`.
Se durante a execução alguma decisão do PRD precisar mudar de verdade, o caminho é o de
sempre: aprovação do dev e registro em `docs/51-apk-no-preview/variance_report.md`.

---

## 9. Fora de escopo (não volta como surpresa)

Config em runtime / deep link no app (saída **(a)**, que vira item novo do roadmap na T2.5);
APK por projeto sob demanda (saída (b)); iOS/IPA; keystore de release de verdade (A4›S2);
Play Store, atualização in-app, canal beta; analytics (não existe infraestrutura, e este item
não funda uma); qualquer mudança no `AppConfig` do **app de demonstração**; e **E2E**, script
ou roteiro (D13).

---

## 10. Definition of Done

- [ ] **T1.1–T2.5 satisfazem seus DoD**, e as seis tarefas que mudam comportamento (T1.1,
      T1.2, T2.1, T2.2, T2.3, T2.4) passaram pelo `supervisor-dod`.
- [ ] **Um `push` em `develop` publica o asset.** A execução do job em `develop` sai verde e
      `curl -sIL https://github.com/euclidesgc/driva/releases/download/demo-app-latest/driva-demo-hml.apk`
      devolve `200` sem autenticação; a release está marcada **pre-release** e o selo _Latest_
      da página continua na release SemVer do produto.
- [ ] **A cancela de PR não mudou:** o job `android` segue em `--debug`, o job novo não roda em
      `pull_request`, e `permissions: contents: write` aparece só dentro dele.
- [ ] **Com URL preenchida**, a janela "Ver no celular" mostra o botão `Baixar APK de teste`
      abaixo do QR e do link, com o aviso de demonstração fixa e a linha do iPhone; **com URL
      vazia**, não há botão nem espaço reservado.
- [ ] **O clique aciona o `NewTabLauncher` com exatamente a URL da config**, provado por
      injeção no teste.
- [ ] **O teste que monta a árvore a partir da rota** existe e prova que a URL sai do
      `AppConfig` e chega ao diálogo — sem ele o item não fecha, porque é o único que pega o
      elo esquecido.
- [ ] `bash scripts/gates_guard.sh`, `dart format --set-exit-if-changed`, `flutter analyze`,
      `flutter test -r compact` (editor e app de demonstração) e `dart test -r compact`
      (kernel) **verdes**.
- [ ] **Nenhum arquivo de E2E** nasceu neste item: `ls docs/51-apk-no-preview/` não tem
      `e2e_hml.sh`, `e2e_shots.sh`, `e2e_drive.mjs` nem `e2e_roteiro.md`.
- [ ] **Parecer do CISO** em `docs/51-apk-no-preview/ciso_review.md`, cobrindo o
      `contents: write`, a exposição pública do APK e a dependência do `GET /v1/projects` sem
      autenticação.
- [ ] `CHANGELOG.md`, `docs/deploy/coolify.md`, `docs/roadmap.md` (item 51 `[x]` na saída (c),
      item novo da saída (a), linha em _Validações de campo pendentes_) e
      `docs/51-apk-no-preview/final_report.md` atualizados.

_A régua é a pirâmide automatizada (decisão do dono, 2026-08-21). **V1–V5 não bloqueiam o
`[x]`** — vão para `docs/roadmap.md` › _Validações de campo pendentes_, e o dono roda quando
tiver o aparelho._
