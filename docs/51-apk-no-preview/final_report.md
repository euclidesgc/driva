# Relatório final — item 51: baixar o APK de teste na janela de preview

> Fechado em 2026-08-22, na saída **(c)** do item 51 (APK de demonstração fixa). Planejamento em
> [`plan.md`](plan.md), contrato em [`prd.md`](prd.md), discovery técnico em [`specs.md`](specs.md).
> Duas PRs empilhadas: `feature/51-ci-publica-apk` (F1) e `feature/51-editor-download-apk` (F2).

## O que ficou pronto

**A CI publica o APK de demonstração a cada `push` em `develop` (F1).** Job novo
`publish-demo-apk` em `.github/workflows/ci.yml`, separado do job `android` de sempre (que
continua `--debug`, cancela de PR). Builda `flutter build apk --release --target
lib/main_hml.dart` chamando `apps/driva_demo_app/tool/run_demo.sh MODE=apk` — a mesma
descoberta de chave via `GET /v1/projects` que já existia, sem reimplementá-la —, agora com uma
verificação prévia (`GET /v1/public/contents/<slug>` com o header `x-driva-key`) que aborta o
build antes de gerar um APK com vitrine vazia. `contents: write` vive só dentro do job novo; o
topo do workflow segue `contents: read`.

**O editor oferece o download, junto do QR (F2).** `AppConfig` ganha `demoApkUrl`, lido de
`--dart-define`/`config/<env>.json` em dev e hml e vazio em prod/fake — e, no mundo implantado,
de uma `ARG` do `Dockerfile` alimentada por Build Variable do Coolify (o config JSON sozinho não
chega ao editor publicado). O valor desce por **cinco** elos até `PreviewShareDialog`
(`EditorWorkspaceHost` → `EditorWorkspace`, com **duas** chamadas de `CenterArea` → `CenterArea`
→ `CanvasArea`), todos `required` para que esquecer de ligar um vire erro de compilação, não um
botão que some em silêncio. O widget `DemoApkDownloadBlock`, irmão de `PreviewInstallHint`, some
por completo quando a URL está vazia — nem botão morto, nem espaço em branco.

## Como operar o asset

- **URL fixa**:
  `https://github.com/euclidesgc/driva/releases/download/demo-app-latest/driva-demo-hml.apk`.
- **O tag `demo-app-latest` não se move** — nasce no primeiro `push` que o publica e fica lá; só
  a nota da release (`gh release edit --notes`) é atualizada a cada execução, com o SHA e a
  data UTC do build corrente. É assim que se confere a frescura sem versão na tela do editor.
- **Republicar à mão**, se precisar sem esperar um `push` em `develop`:
  ```bash
  cd apps/driva_demo_app
  MODE=apk TARGET=lib/main_hml.dart API=https://api-hml.driva.duckdns.org \
    PROJECT_TITLE="Megazord - App RE" ./tool/run_demo.sh
  gh release upload demo-app-latest \
    build/app/outputs/flutter-apk/driva-demo-hml.apk --clobber --repo euclidesgc/driva
  ```
- **Duas variáveis de repositório, ambas em `vars.*` (nunca `secrets.*`)**:
  `DEMO_PROJECT_TITLE` (hoje `Megazord - App RE` — é o único projeto de hml com o slug `home`
  publicado; sem ela o job pega o primeiro projeto por `updatedAt desc`, que hoje **não** tem
  conteúdo publicado e faz o job falhar) e `DEMO_SLUG` (vazia = `home`, o default). Configuradas
  via `gh variable set` nesta sessão.
- **A Build Variable `DEMO_APK_URL` no recurso de homologação do Coolify** é passo manual do
  dono, fora do alcance da CI — ver `docs/roadmap.md` § _O que ainda precisa do humano_. Sem
  ela, o editor implantado em hml não mostra o botão mesmo com as duas PRs mergeadas.

## Como isto foi provado

Pirâmide automatizada, com o E2E suspenso desde 2026-08-20 (`CLAUDE.md` › _Método de
trabalho_) — nenhuma linha de E2E, script ou roteiro, nasceu neste item.

- **F1**: sem Dart novo (é bash + YAML). Prova por comando literal — `bash -n`, `grep` de
  ausência (`secrets.`, `v1/projects`), parse de YAML — todos rodados pelo `supervisor-dod` de
  cada tarefa e revalidados pelo `qa` na revisão de fase.
- **F2**: widget isolado (`demo_apk_download_block_test.dart`), e o teste que **monta a árvore a
  partir da rota** (`editor_demo_apk_wiring_test.dart`) — prova que a URL sai do `AppConfig` no
  `pageBuilder` e chega ao diálogo pela cadeia real, o único jeito de pegar um elo do fio
  esquecido em silêncio. `preview_share_dialog_test.dart` cresce com os casos de URL
  preenchida/vazia nos três tamanhos já cobertos.
- `scripts/gates_guard.sh`, `dart format`, `flutter analyze` e a suíte completa do editor e do
  app de demonstração, verdes.

## Validações de campo pendentes

_(E2E suspenso — o que só o hardware ou o navegador real provam não bloqueia o fechamento; vai
para `docs/roadmap.md` › **Validações de campo pendentes**, e o dono roda quando tiver o
aparelho.)_

| # | O que só o aparelho/navegador real prova |
|---|---|
| V1 | O `.apk` publicado **instala** num Android físico, partindo do link do editor |
| V2 | Instalado, o app **mostra o conteúdo de demonstração** — prova de que a chave e o slug resolvidos pelo job (`DEMO_PROJECT_TITLE`) estão certos, não o placeholder |
| V3 | O build de **release** (AOT + tree-shake de ícones) não produz "tofu" nem ícone faltando |
| V4 | **Reinstalar por cima** de uma versão anterior: confirma que o aviso do bloco ("desinstale antes de instalar esta") descreve o que o Android de fato faz com a assinatura de debug |
| V5 | O clique no botão **baixa** o arquivo no navegador do desktop, em vez de abrir uma aba com lixo binário |

## Dívidas que ficam

- **A saída (a) do item 51** — app genérico com configuração em runtime (deep link/QR de
  config), que faria o APK abrir o conteúdo exato em edição — nasce como **item novo** no
  roadmap, registrado no fechamento. O item 51 fecha explicitamente na saída (c).
- **R6, herdado do item 26**: o job de CI depende de `GET /v1/projects` sem autenticação.
  Quando a auth chegar, este é um dos call sites que quebram — registrado no gate do CISO.
- **Assinatura de debug** no APK de release (A4›S1). Keystore real vira débito de distribuição,
  não deste item.

## Fora de escopo, por decisão registrada

Config em runtime / deep link no app; APK por projeto sob demanda; iOS/IPA; keystore de release
de verdade; Play Store, atualização in-app, canal beta; analytics (não existe infraestrutura, e
este item não funda uma); qualquer mudança no `AppConfig` do app de demonstração. Detalhado em
`prd.md` › _Fora de escopo_ e `plan.md` § 9.
