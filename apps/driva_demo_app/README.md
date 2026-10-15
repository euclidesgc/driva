# driva_demo_app

App de demonstração do driva: faz o que o app de um cliente fará — busca um
conteúdo na API pública e monta a tela com o renderer (`sdui_flutter`). Nenhuma
tela daqui está no código: todas vêm do spec.

É o **primeiro consumidor externo do renderer** e o embrião do package de
runtime previsto no item 25 do roadmap. Ver `docs/13-loop-sdui/`.

## Rodar

O jeito curto — o script descobre a chave publicável do projeto na API e injeta
como dart-define:

```bash
./tool/run_demo.sh                                     # localhost:3000
API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
DEVICE=chrome PROJECT_TITLE="Meu projeto" ./tool/run_demo.sh
```

Na mão, com a chave que o editor mostra em `GET /v1/projects`:

```bash
flutter run -d chrome --target lib/main_dev.dart \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=PUBLISHABLE_KEY=pk_...
```

## Gerar o APK release (Android físico)

O mesmo script, em modo `apk` — ele descobre a chave do ambiente e a embarca no
binário:

```bash
MODE=apk TARGET=lib/main_hml.dart API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
```

O APK sai em `build/app/outputs/flutter-apk/app-release.apk` (assinado com a
chave de debug — é build de demonstração, não vai para loja).

Use o **mesmo Flutter que a CI fixa** (`.github/workflows/ci.yml`): o
`android/settings.gradle.kts` traz AGP 9.0.1, e um SDK mais antigo falha na
configuração do Gradle com erro de Kotlin DSL (`Unresolved reference
'compilerOptions'`) que não tem relação aparente com a causa.

**Não gere o release por `--dart-define-from-file=config/hml.json`:** os
`config/<env>.json` versionados trazem `PUBLISHABLE_KEY` de placeholder (ver
abaixo). O build passa, o app abre, e a vitrine fica vazia porque a API devolve
404 para a chave inexistente.

## Publicar um conteúdo de vitrine

O app só mostra o que existe no projeto. Para ter algo rico na tela:

```bash
docs/13-loop-sdui/evidencias/seed_vitrine.sh                       # local
API=https://api-hml.driva.duckdns.org docs/13-loop-sdui/evidencias/seed_vitrine.sh
```

## Ações executadas

Os eventos do spec chegam ao app pelo `onAction` do `DrivaContent`, e o
`ContentActionRunner` (`lib/modules/published_module/presentation/content/actions/`)
os executa. Cinco ações rodam de verdade:

- `navigate`: abre o `slug` na mesma tela e guarda o anterior numa pilha. Slug
  inexistente mostra "Conteúdo não encontrado", e dá para voltar.
- `navigateBack`: volta para o slug anterior da pilha. Sem histórico, volta
  para a rota abaixo da tela, se houver; na tela inicial, não faz nada e não
  fecha o app.
- `showSnackBar`: mostra `message` por `durationMs` (padrão de 4 s), com
  `backgroundColor` em hex (`#RRGGBB` ou `#AARRGGBB`). Duração ou cor inválidas
  caem no padrão.
- `copyToClipboard`: copia `text` sem aviso próprio. Para avisar, encadeie um
  `showSnackBar`.
- `launchUrl`: abre `url` fora do app, no navegador ou no app que o sistema
  associa ao endereço. Se o endereço não tiver esquema ou o sistema não abrir,
  aparece "Não foi possível abrir o link.".

Continuam só como o aviso "Ação recebida: ...": `wait`, `apiCall`, qualquer tipo
fora dessa lista e a ação cujo parâmetro obrigatório não é um texto literal (um
binding, por exemplo).

Limites:

- O botão voltar do sistema não percorre a pilha de slugs: no Android, ele sai
  do app. A pilha é zerada quando um slug é aberto pela barra de baixo.
- Um nó com `onTap` e `onDoubleTap` espera o tempo do toque duplo antes de
  confirmar o toque simples. Com `onTap` sozinho, o toque é imediato.
- O `launchUrl` aceita qualquer esquema, porque quem monta a página é o dono do
  projeto e este app é uma referência. Um app cliente de produção deve limitar
  os esquemas a uma lista permitida (por exemplo `https`, `mailto`, `tel` e o
  deep link do próprio app) antes de chamar o sistema.

O `url_launcher` é dependência só deste app (`pubspec.yaml`): o `driva_client`
não executa ações, só as repassa. Abrir URL em Android 11+ e iOS físicos ainda
não foi validado em aparelho.

## Configuração

`config/<env>.json` define `API_BASE_URL` e `PUBLISHABLE_KEY`. A chave é
publicável por natureza (só lê conteúdo, nunca escreve), mas é **por
ambiente** — a de homologação não é a mesma do banco local, por isso os arquivos
versionados vêm com um placeholder e quem preenche é o `run_demo.sh`, que
descobre a chave na API e a injeta como dart-define nos dois modos (`run` e
`apk`).
