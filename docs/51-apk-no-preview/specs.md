# Specs — Download do APK de teste ao lado do QR do preview

> **Item 51 do roadmap** (Marco 6), executado na saída **(c)** — _APK fixo de demonstração_.
> Pedido do humano em 2026-08-20, discovery em 2026-08-22.
>
> **Status desta spec: aguardando as decisões A1–A8 do dev.** As opções, o custo de cada
> uma e a recomendação estão em [Decisões pendentes](#decisões-pendentes-do-humano). O
> escopo (E1) já veio travado e **não se reabre**. Enquanto A1 não voltar, o `tech-lead`
> **não** escreve o `plan.md` — A1 decide A2, A3 e A5.

---

## O pedido

Na janela **"Ver no celular"** do editor — que hoje oferece QR code, link copiável e a dica
de instalar o preview como PWA — entra um caminho a mais: **baixar o APK do app de
demonstração** e instalá-lo no aparelho. O objetivo é ver o SDUI desenhado por um app de
verdade, e não por uma aba de navegador.

A CI passa a buildar o APK de **release** do `driva_demo_app` e a publicá-lo num lugar de
onde o editor consiga linkar.

---

## O escopo que já veio travado (E1) — e o nome dele no roadmap

**Decisão do dono, em conversa anterior ao discovery:** o app baixado abre **sempre o mesmo
projeto/conteúdo de demonstração**, não o conteúdo que está aberto no preview.

Isso é a saída **(c)** do item 51 do roadmap (`docs/roadmap.md:190`) — _"APK fixo de
demonstração"_ —, e não a **(a)**, que o roadmap recomendava. A troca de nome importa
porque o pedido chegou ao discovery como "Opção A": **"Opção A" do pedido = "(c)" do
roadmap**, e a "Opção B" do pedido (deep link / config em runtime) = **"(a)" do roadmap**.
Sem esse mapeamento escrito, o roadmap e esta spec passariam a se contradizer.

O motivo técnico é o que o roadmap já registrava como _"a armadilha que decide o desenho"_:

> `publishableKey` e `defaultSlug` do app vêm de `String.fromEnvironment`
> (`apps/driva_demo_app/lib/core/config/app_config.dart:13-25`) — ficam **assados no
> binário**. E o app **não tem deep link**: o `AndroidManifest.xml` declara só
> `MAIN`/`LAUNCHER`.

Fazer o APK abrir o conteúdo exato do preview exige config em runtime + intent-filter no
app e um QR de configuração no editor. **Está fora deste item, por decisão do dono**, e vira
débito no roadmap (ver [Fora de escopo](#fora-de-escopo-declarado-para-não-voltar-como-surpresa)).

**Consequência de produto que a UI tem de assumir:** quem clicar no botão a partir de um
conteúdo qualquer vai instalar um app que mostra **outro** conteúdo. Se a tela não disser
isso, o botão mente — e o próprio roadmap classificou a saída (c) como a que _"engana mais
do que ajuda"_. **O aviso na UI não é enfeite: é o que torna a decisão E1 honesta**, e é o
assunto da A6.

---

## Estado atual, levantado no código (2026-08-22)

### A superfície de UI já existe

`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart`
— um `AlertDialog` com título "Ver no celular", `QrImageView`, caixa com o link + botão de
copiar, e o `PreviewInstallHint` (a dica de "Adicionar à tela inicial"). Todo o estilo já sai
de token (`AppSpacing`, `AppRadii`, `AppTypography`, `EditorColors`) — o Gate 4 está
satisfeito hoje e continua valendo para o que entrar.

Quem abre: `canvas_area.dart:113-133` (`_openPreviewDialog`), que monta a URL a partir de
`Uri.base.origin` + `namedLocation(EditorRoutes.previewName, …)`.

Teste existente: `test/…/canvas/preview_share_dialog_test.dart` — monta o diálogo em três
larguras e confere título e link. **É o arquivo que cresce**, não um novo.

### Como o editor recebe configuração

`apps/driva_editor/lib/core/config/app_config.dart` — `AppConfig.fromEnvironment` lê
`API_BASE_URL`, `DEFAULT_PROJECT_ID` e `USE_FAKE_DATA` de `--dart-define-from-file`. Quatro
arquivos em `apps/driva_editor/config/`: `dev`, `fake`, `hml`, `prod`.

**O `AppConfig` só é lido no `pageBuilder`** (a regra do repositório: página é o único lugar
que toca o `getIt`). O precedente exato de como um valor de config desce até o
`canvas_area` já está no código: `imageUrlResolver` sai de `editor_page.dart:114`
(`imageUrlResolverFor(getIt<AppConfig>())`), passa por `center_area.dart:45` e chega em
`canvas_area.dart:18` como parâmetro **nullable**. É o caminho a imitar — e é também a
armadilha conhecida do repositório: **parâmetro opcional nulo esconde dependência**, e já
produziu defeitos invisíveis para o `analyze` e para a suíte. O teste que fecha isso monta a
árvore **a partir da rota**, não o widget solto.

### Como o APK é gerado hoje

`apps/driva_demo_app/tool/run_demo.sh` em `MODE=apk`:

1. `curl $API/v1/projects` e pega o `publishableKey` do primeiro projeto (ou do de título
   `PROJECT_TITLE`);
2. valida que a chave começa com `pk_` e que a API não é `http://` (o targetSdk bloqueia
   cleartext em release);
3. `flutter build apk --release --target <TARGET> --dart-define=API_BASE_URL=… --dart-define=PUBLISHABLE_KEY=…`;
4. saída em `build/app/outputs/flutter-apk/app-release.apk`.

**A chave real nunca é versionada.** Os `config/<env>.json` do app trazem
`"PUBLISHABLE_KEY": "cole-aqui-a-chave-do-projeto"`, e há um segundo mecanismo já escrito
para resolvê-la: `.vscode/scripts/resolve-demo-key.sh` gera um `config/<env>.local.json`
(ignorado pelo git, ver `.gitignore` do app) com a chave descoberta na API. **São duas
implementações do mesmo "descubra a chave no `GET /v1/projects`"** — é a convenção da casa, e
a A2 decide se a CI vira a terceira.

_Nota de rodapé do pedido: o caminho é `apps/driva_demo_app/tool/run_demo.sh`; `tool/` na
raiz do repositório não existe._

_Trabalho não commitado no momento do discovery:_ `apps/driva_demo_app/lib/main_prod.dart` e
`apps/driva_demo_app/config/prod.json` estão como **untracked** no working tree — o flavor de
produção do app está nascendo agora. Isso encosta na A8.

### A CI hoje, e as duas invariantes que ela declara

`.github/workflows/ci.yml`:

- Roda em `pull_request` para `develop`/`main`/`feature|bugfix|hotfix|release|docs/**` e em
  `push` para `develop`/`main`.
- **`permissions: contents: read`** no topo, com a razão escrita: _"Nenhum job usa
  `secrets.*` nem escreve no repositório, e o job de Android baixa e executa código de plugin
  de terceiros"_.
- Job `android` (`needs: flutter`): builda **`--debug`** com `main_dev.dart`, **sem
  dart-define nenhum**. O comentário explica que é debug de propósito (a regressão de
  toolchain morre na configuração do Gradle, e `assembleDebug` custa 41,7s contra 86,8s do
  `assembleRelease`), e **sem filtro de path de propósito** (o app está no pub workspace).
- O mesmo comentário nomeia o que esse job **não** cobre: _"o que só o release exercita — AOT
  (`gen_snapshot`) e o tree-shake de ícones"_.

**Toda decisão de publicação mexe nessas duas invariantes** (zero `secrets.*`, token
read-only) e precisa dizer como. Ganho colateral, se a A3 levar a um build de release na CI:
o buraco do AOT/tree-shake que o próprio comentário registra passa a ser exercitado.

### A assinatura do release é a de debug — e isso tem consequência

`apps/driva_demo_app/android/app/build.gradle.kts:31-32`:

```kotlin
// Signing with the debug keys for now, so `flutter run --release` works.
signingConfig = signingConfigs.getByName("debug")
```

Não há keystore no repositório. Numa máquina de CI, o `debug.keystore` é gerado (ou vem da
imagem) **por execução**, então **não há garantia de que dois APKs publicados tenham a mesma
assinatura**. Quando não têm, o Android recusa a atualização com _"app não instalado"_ e o
usuário precisa **desinstalar a versão anterior** antes. O roadmap já previa isto:
_"sem ele, cada build novo obriga a desinstalar o anterior"_. É o assunto da A4.

### O storage que existe — e o que ele **não** faz

`docs/deploy/coolify.md:98-117`: **Garage** (S3-compatível) em `https://s3.bmjtech.duckdns.org`,
buckets `driva-hml` (quota **2 GiB**) e `driva-prod` (5 GiB), **credencial própria por
ambiente**, `S3_KEY_PREFIX` vazio. Envs só no Coolify, **nunca no repo**.

Três fatos que mudam a pergunta 1 do pedido:

1. **O bucket não tem leitura anônima.** Nada no repositório lê um objeto do Garage por URL
   pública. O que existe é **proxy pelo backend**: `projects.controller.ts:109-115`
   (`GET /v1/projects/:id/image`) chama `storage.get(key)` e devolve os bytes. Publicar um
   APK "no bucket" e linkar direto **exige criar** política de leitura anônima onde hoje ela
   não existe — e o `driva-hml` guarda também a mídia dos projetos.
2. **O `get` do adapter carrega o objeto inteiro em memória** (`s3-storage.service.ts:107-110`,
   `transformToByteArray()`). O container do backend tem teto de **512M**
   (`docs/deploy/coolify.md:124-133`). Servir um APK de dezenas de MB por esse caminho é uma
   decisão de arquitetura, não um detalhe.
3. **O host é um Oracle free tier de 2 vCPU** e o Garage roda nele. Download de APK sai da
   mesma banda que serve a API e o editor, e cada build ocupa a quota que a mídia dos
   projetos divide.

### O precedente de "público sem autenticação" já existe

`backend/src/public/public.controller.ts` — `/v1/public/contents` e `/v1/public/contents/:slug`
autenticam por `publishableKey` no header, com `ETag` e
`Cache-Control: public, max-age=60, must-revalidate`. O `AppConfig` do app comenta a
natureza da chave: _"feita para viajar no binário: ela só lê conteúdo publicado, nunca
escreve"_.

**E o repositório é público**: `gh repo view` → `euclidesgc/driva`, `PUBLIC`. Todo o
código-fonte já é aberto; um binário de demonstração não muda a categoria de exposição. É a
confirmação que a A7 formaliza.

### Não há analytics no editor

Varredura por `analytics`/`telemetry` em `apps/driva_editor/lib` e `backend/src`: **zero
ocorrências**. O que existe de observabilidade é `runZonedGuarded` + `AppBlocObserver` no
`bootstrap.dart`. A seção _Analytics_ do `prd.md` registra o que **seria** instrumentado, sem
inventar infraestrutura neste item.

---

## O que **não** se reabre nesta spec

- **O escopo E1** — APK de demonstração fixo, sem deep link. Decisão do dono, anterior ao
  discovery.
- **iOS.** Sideload de IPA exige TestFlight ou ad-hoc com UDID registrado. Para iPhone o
  caminho continua sendo o preview web instalável, que já existe. A tela **diz isso** (A6) em
  vez de deixar o usuário procurar um botão que não vem.
- **A chave publicável ser pública.** É o desenho, desde a fatia 1 do item 25.
- **O 404 do backend, o `x-project-id`, a auth** — nada aqui os toca.

---

## Decisões pendentes do humano

> Cada bloco tem opções, custo e **recomendação**. **A1 destrava A2, A3 e A5** — se só houver
> tempo para uma resposta, que seja essa.

**Fechadas pelo tech-manager, seguindo a recomendação de cada bloco (todas técnicas, sem
ambiguidade de produto):**

- **E1** (escopo) — dono reconfirmou (c), diante do aviso do roadmap, com aviso explícito na
  tela como mitigação (é o que a A6 escreve).
- **A1** — GitHub Releases (H1), tag `demo-app-latest`, `contents: write` só no job novo.
  Confirmado pelo dono.
- **A2** — chave descoberta em `GET /v1/projects` na hora do build (K1).
- **A3** — publica em todo `push` em `develop`, job separado do `android` de hoje (G1).
- **A4** — aceita a assinatura de debug agora; keystore real vira débito. O aviso de
  reinstalar por cima vive no texto da A6 (S1).
- **A5** — `DEMO_APK_URL` em `AppConfig`; vazio ⇒ botão não aparece (E1 desta pergunta, sem
  request em runtime).
- **A7** — exposição pública do APK com `pk_` embarcado é aceitável; registrar no gate do
  CISO.
- **A8** — publica só para `hml`; `prod.json` do editor fica vazio (A).

**A única em aberto é a A6** — textos são produto, e o tech-manager levou ao dono uma
proposta para aprovação/edição em vez de decidir sozinho.

### A0 — Numeração da pasta — resolvida pelo tech-manager

Esta doc nasceu em `docs/54-download-apk-preview/` por instrução do despacho, mas **não
existe item 54 no roadmap** — o item deste trabalho é o **51**, e a convenção da casa
(registrada na A5 do item 46) é numerar a pasta **pelo item do roadmap**: `docs/46-…`,
`docs/50-…`, `docs/24-…`. Renomeada para `docs/51-apk-no-preview/`. O item **51** fecha com a
saída (c); a saída (a) — config em runtime + deep link — nasce como item novo no roadmap no
fechamento.

### A1 — Onde o `.apk` fica hospedado **⟵ a que destrava as outras**

| Opção | Como funciona | O que ganha | O que custa |
|---|---|---|---|
| **H1 — GitHub Releases** _(recomendada)_ | Job novo na CI faz `gh release upload --clobber` num **tag fixo** (`demo-app-latest`, marcado como _pre-release_), com `GITHUB_TOKEN` e `permissions: contents: write` **só nesse job** | O repositório **é público** → a URL do asset é estável, previsível e baixa **sem autenticação**; **nenhuma credencial de infra sai do Coolify**; nenhum endpoint novo; banda e storage são do GitHub; o "build ainda não existe" vira uma página 404 do GitHub, não um crash | Quebra a invariante _"nenhum job escreve no repositório"_ (mitigada: `contents: write` por job, e o job só roda em `push` para `develop` — PR de fork jamais o dispara); a release rolante aparece na página de Releases junto das releases de produto |
| **H2 — Garage direto pela CI** | `aws s3 cp` para `driva-hml` com `S3_ACCESS_KEY`/`S3_SECRET_KEY` em GitHub Secrets | Usa a infra que já existe | **Move uma credencial de infra do Coolify para o GitHub** — hoje ela nunca sai de lá; **exige criar leitura anônima** no Garage, que não existe (e o `driva-hml` guarda a mídia dos projetos → provavelmente um bucket `driva-public` novo, a operar e documentar); consome a quota de 2 GiB; a banda de download sai do host de 2 vCPU |
| **H3 — Endpoint do backend por cima do Garage** | CI faz `POST` autenticado num endpoint novo; backend grava e serve por `GET /v1/public/demo-app/android` | URL no domínio do produto; controla versão e cache | Tudo o que a H2 custa, **mais** um endpoint de escrita novo (gate obrigatório do CISO), limite de corpo para dezenas de MB e o `transformToByteArray()` de hoje carregando o APK inteiro num container de 512M |

**Recomendo H1**, com folga. É a única que não amplia o raio de exposição de credencial nem
inventa superfície de escrita nova, e o fato de o repositório ser público a torna trivial.

⚠️ **Detalhe que o `plan.md` precisa herdar (H1):** a URL **não** pode usar a forma
`releases/latest/download/…` — no GitFlow deste repositório `latest` resolve para a release
SemVer do produto, que não tem o asset. A forma correta é o **tag fixo**:
`https://github.com/euclidesgc/driva/releases/download/demo-app-latest/<arquivo>.apk`, com a
release marcada `--prerelease` para não roubar o selo _Latest_ das releases de verdade.

### A2 — De onde a CI tira a `PUBLISHABLE_KEY` do build de release

O APK de release **precisa** da chave real: com o placeholder versionado ele compila e mostra
vitrine vazia (404) — o defeito que o item 25 já pagou uma vez.

| Opção | Como | O que ganha | O que custa |
|---|---|---|---|
| **K1 — Descobrir na API** _(recomendada)_ | A CI reusa a lógica de `run_demo.sh`/`resolve-demo-key.sh`: `GET /v1/projects` na hml e pega a chave, com o projeto identificado por uma **variável de repositório** (`vars.DEMO_PROJECT_TITLE`, não secret) | É a convenção que já existe **duas vezes** no repositório; **mantém a invariante `secrets.*` intacta**; nada de chave nova para guardar | O build passa a depender da hml estar de pé; se cair, o job de publicação fica vermelho em `develop` (não bloqueia PR) |
| **K2 — Variável de repositório com a chave** | `vars.DEMO_PUBLISHABLE_KEY` nas configurações do Actions | Determinístico, não depende da hml | Mais um valor a manter fora do repo, que dessincroniza calado se a chave for rotacionada |
| **K3 — Commitar a chave no `config/hml.json`** | Trocar o placeholder pelo `pk_` real | Zero configuração | **Contra a política vigente**: os dois mecanismos existentes foram escritos justamente para **não** versionar a chave, e o `.gitignore` do app tem linha dedicada a isso. Além de virar candidato a alerta do GitGuardian |

**Recomendo K1.** Falhar alto quando a hml está fora é preferível a publicar um APK com
chave errada — o link ficaria parado numa versão boa em vez de entregar uma quebrada.

### A3 — Gatilho e frequência da publicação

| Opção | Quando publica | O que ganha | O que custa |
|---|---|---|---|
| **G1 — Todo `push` em `develop`** _(recomendada)_ | Job novo, `if: github.event_name == 'push' && github.ref == 'refs/heads/develop'`, sobrescrevendo o asset do tag fixo | O link **sempre** aponta para o que está em homologação — que é o propósito do botão; nenhum PR gera nem sobrescreve artefato; nada a lembrar de bumpar | ~90s de `assembleRelease` por merge em `develop` (fora do caminho crítico do PR) |
| **G2 — Só quando `version` do `pubspec.yaml` muda** | Compara o campo `version` com o commit anterior | Menos builds | O link fica **stale em relação à `develop`** — e a pergunta "minha mudança está nesse APK?" volta a não ter resposta, que é exatamente o que este item existe para resolver. Bumpar vira ritual manual que alguém esquece |
| **G3 — `workflow_dispatch` manual** | Botão no Actions | Controle total | Alguém precisa lembrar; entre dois cliques, o link mente sem avisar |

**Recomendo G1**, e o job de release **entra separado** do job `android` de hoje (que
continua `--debug` como cancela de PR) — assim o PR não fica mais lento, e o AOT/tree-shake
que o comentário do `ci.yml` declara descoberto passa a rodar em `develop`.

### A4 — Assinatura: o APK que substitui o anterior

| Opção | O que é | O que ganha | O que custa |
|---|---|---|---|
| **S1 — Aceitar a chave de debug e avisar na UI** _(recomendada)_ | Nada muda no Gradle; a tela diz "se já tiver uma versão instalada, desinstale antes" | Zero segredo novo, zero configuração | Cada instalação nova pode exigir desinstalar a anterior — e **quando o Android recusar, a mensagem dele não explica nada**; quem explica é o texto do editor |
| **S2 — Keystore de release em GitHub Secrets** | `.jks` em base64 + `key.properties` gerado no job | Assinatura estável, caminho correto para distribuição de verdade | Cria **um segredo real** a guardar e rotacionar, quebra a invariante `secrets.*` e é decisão de política, não de implementação |
| **S3 — Keystore de debug fixo, versionado** | Commitar um `debug.keystore` (senha pública `android`, sem valor de segurança) | Assinatura estável sem segredo nenhum | Arquivo de chave num repositório **público**: candidato garantido a alerta do GitGuardian e a "cheiro" recorrente em toda revisão futura |

**Recomendo S1 agora e S2 como débito**, porque keystore de verdade só faz sentido quando
houver distribuição de verdade — e aí a decisão é do dono, não do plano.

### A5 — Como o editor descobre a URL, e o que ele mostra se o build não existe

| Opção | Como | O que ganha | O que custa |
|---|---|---|---|
| **E1 — `DEMO_APK_URL` no `AppConfig`** _(recomendada)_ | Mais um `String.fromEnvironment`, presente nos `config/<env>.json`; **vazio ⇒ botão não aparece** | Zero request, zero dependência externa em runtime; o precedente de threading (`imageUrlResolver`) já está no código; ambiente sem APK simplesmente não mostra o botão | Não sabe se o asset existe **agora**: se a publicação falhou, o clique cai numa página 404 do GitHub (feio, mas nem crash nem tela em branco) e não mostra data/versão do build |
| **E2 — API do GitHub em runtime** | `GET /repos/euclidesgc/driva/releases/tags/demo-app-latest` (CORS liberado, 60 req/h por IP sem token) | Botão sabe se existe, e mostra **versão e data** do build — que é o que dá sentido a "aponta para o build mais recente" | Uma fatia clean-arch nova no editor (use case + model zard + estado no cubit) e uma dependência de runtime em `github.com` |
| **E3 — Endpoint no backend** | Backend guarda/repassa a URL corrente | URL no domínio do produto | Só faz sentido casado com H3; caro pelo mesmo motivo |

**Recomendo E1.** Se o dono quiser ver **versão e data** do build na tela — e é um desejo
legítimo, porque é o que prova a frescura do link —, então **E2**, e aí isso vira uma fase
própria no `plan.md`, não um detalhe.

### A6 — O que o botão diz — aprovado pelo dono

1. **Rótulo do botão:** `Baixar APK de teste`.
2. **Aviso obrigatório** (o que impede a decisão E1 de virar promessa falsa): `Este é um app
   de demonstração com um conteúdo fixo — não mostra o que você está editando agora.`
3. **iOS:** `No iPhone, use o preview instalável acima.`
4. **Fonte desconhecida + reinstalação** (A4›S1): `O Android vai pedir permissão para
   instalar de fonte desconhecida. Se já tiver uma versão instalada, desinstale antes de
   instalar esta.`

**Forma:** um bloco irmão do `PreviewInstallHint` (mesmo desenho, mesmos tokens), **abaixo
dele**, com o botão e o aviso juntos — para que ninguém veja o botão sem ver a ressalva.
Widget próprio, arquivo próprio (Gates 1 e 3), tudo por token (Gate 4).

### A7 — Confirmação de exposição (segurança)

O APK fica **público, sem autenticação**, e carrega dentro de si a `publishableKey` do
projeto de demonstração — chave que **só lê conteúdo publicado, nunca escreve**, e que já é
pública por natureza. O repositório inteiro já é público.

**Confirmação pedida:** isso é aceitável? _Recomendo **sim**_ — é a mesma categoria de
exposição do `/v1/public` e do próprio código-fonte, e o CISO deve registrar por escrito no
gate da fase.

⚠️ **O que eu levantei junto e você não perguntou:** o `GET /v1/projects` que a A2›K1 usa
devolve **a `publishableKey` de todos os projetos, sem autenticação nenhuma**. Isso é débito
conhecido do item 26 (auth) e **não nasce aqui** — mas este item passa a **depender** dele.
Vale a linha no `variance_report`/CISO: quando a auth chegar, o job de CI da A2 é um dos
call sites que quebram.

### A8 — Qual ambiente o APK aponta

O APK de release é buildado contra uma API. O `main_hml.dart` aponta para a hml; o
`main_prod.dart` está **nascendo agora** no working tree.

| Opção | O que publica | Custo |
|---|---|---|
| **A** _(recomendada)_ | Só o flavor **hml**. `config/hml.json` e `config/dev.json` do editor recebem a URL; `prod.json` fica **vazio** ⇒ o botão não aparece no editor de produção | Mínimo; e o editor de produção não oferece um app que fala com homologação |
| **B** | Publica hml **e** prod, cada editor linkando o seu | Dobra o tempo de build, exige um projeto de demonstração em produção e a chave dele; e hoje não há uso real do editor de produção |

**Recomendo A**, com B entrando quando existir projeto de demonstração em produção.

---

## Fora de escopo (declarado, para não voltar como surpresa)

- **Config em runtime / deep link no app** (a saída **(a)** do item 51) — o app receber
  `key`/`slug` por App Link ou por leitura de QR, e um binário servir qualquer projeto.
  **Vira item próprio do roadmap** (ver A0). É o que faria o botão abrir *o conteúdo em
  edição*, e é o que a decisão E1 adiou conscientemente.
- **APK por projeto, buildado sob demanda** (saída **(b)**) — job de CI por clique, storage
  por projeto, minutos de espera. Descartado no discovery, não volta como sugestão.
- **iOS / IPA** — barreira de plataforma, não de escopo.
- **Keystore de release de verdade** — débito da A4›S2, quando houver distribuição real.
- **Play Store, atualização in-app, canal beta** — nada disto é este item.
- **Mudar o `AppConfig` do app de demonstração** para ler configuração em runtime — é
  exatamente a saída (a); tocar nisso aqui seria fazer o item adiado pela metade.

---

## Decisões que sustentam esta spec

| # | Decisão | Estado |
|---|---|---|
| E1 | APK **fixo de demonstração** (saída (c) do item 51); deep link/config em runtime fica fora | **travada pelo dono**, antes do discovery |
| A0 | Numeração da pasta e arrumação do roadmap | **pendente** — recomendação: renomear para `51-` |
| A1 | Onde o APK fica hospedado | **pendente** — recomendação: GitHub Releases, tag fixo |
| A2 | De onde a CI tira a `PUBLISHABLE_KEY` | **pendente** — recomendação: descobrir na API (K1) |
| A3 | Gatilho da publicação | **pendente** — recomendação: todo `push` em `develop` (G1) |
| A4 | Assinatura do APK | **pendente** — recomendação: aceitar debug + avisar (S1) |
| A5 | Como o editor descobre a URL / estado vazio | **pendente** — recomendação: `DEMO_APK_URL` no `AppConfig` (E1) |
| A6 | Textos do botão e do aviso | **pendente** — produto, precisa da sua redação |
| A7 | Confirmação de exposição pública | **pendente** — recomendação: aceitar, com registro do CISO |
| A8 | Qual ambiente o APK aponta | **pendente** — recomendação: só hml (A) |

## Decisões herdadas (não reabertas)

| # | De onde | O que diz |
|---|---|---|
| Item 25 | `docs/roadmap.md:179` | A receita de build release (`run_demo.sh MODE=apk`) e o `INTERNET` no manifest já existem; a chave real **não** se versiona |
| Item 41 / D31 | `preview_install_hint.dart` | O preview web é instalável como PWA — é o caminho do iOS, e continua sendo |
| Item 51 | `docs/roadmap.md:189-192` | A chave é compile-time; distribuição é metade do trabalho; iOS fica fora por plataforma |
| Débito auth | item 26 | `GET /v1/projects` sem autenticação é débito aceito — e este item passa a depender dele |
