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

## Publicar um conteúdo de vitrine

O app só mostra o que existe no projeto. Para ter algo rico na tela:

```bash
docs/13-loop-sdui/evidencias/seed_vitrine.sh                       # local
API=https://api-hml.driva.duckdns.org docs/13-loop-sdui/evidencias/seed_vitrine.sh
```

## Configuração

`config/<env>.json` define `API_BASE_URL` e `PUBLISHABLE_KEY`. A chave é
publicável por natureza (só lê conteúdo, nunca escreve), mas é **por
ambiente** — a de homologação não é a mesma do banco local, por isso os arquivos
versionados vêm com um placeholder e o script preenche em runtime.
