# Relatório final — Loop SDUI fechado

_Fatia do item 25 do roadmap (API pública + app de exemplo). 2026-08-15._

> **Leia antes o `variance_report.md`.** Esta entrega atravessa uma precedência
> do plano: o item 24 (publicação e versionamento) não existe, então o endpoint
> serve o **rascunho**, não uma versão publicada.

## O que ficou pronto

**Backend — API pública de consumo** (`backend/src/public/`), autenticada pela
chave publicável do projeto no header `x-driva-key`:

| Rota | Comportamento |
| --- | --- |
| `GET /v1/public/contents` | Até 100 conteúdos do projeto da chave (`id`, `name`, `slug`, `updatedAt`) |
| `GET /v1/public/contents/:slug` | Envelope + `spec`, com `ETag` e `Cache-Control` |

Chave ausente, inválida ou de projeto arquivado → `404` genérico.
`If-None-Match` casando → `304`. CORS liberado só neste prefixo (preflight
`204`).

**`Project.publishableKey`** — `pk_` + 32 bytes aleatórios em base64url, gerada
na criação do projeto; a migration deu uma chave a cada projeto existente. É
pública por natureza (vai embarcada no app) e só lê conteúdo.

**App de demonstração** (`apps/driva_demo_app`) — Flutter, Android/iOS/Web, no
pub workspace. Catálogo dos conteúdos → toca → o spec vira tela pelo `SduiView`.
Rodapé mostra a procedência (data do spec + ETag). Sem chave configurada, a tela
explica como obtê-la. `tool/run_demo.sh` descobre a chave na API e sobe o app.

**Fixture de vitrine** — `evidencias/vitrine_spec.json` exercita `listView`,
`container`, `column`, `row`, `text`, `icon`, `card`, `padding`, `divider`,
`button` (com evento), `textField`, `switch` e `checkbox`.
`evidencias/seed_vitrine.sh` publica em qualquer ambiente, idempotente.

## Evidências

- **E2E de contrato** (`evidencias/e2e_public.sh`): **17 PASS / 0 FAIL** contra
  o backend local com o Postgres do `docker-compose`. Cria o próprio conteúdo,
  exercita `200`/`304`/`404`/sem chave/chave inválida/`OPTIONS`/CORS e apaga o
  rastro.
- **E2E visual** (`evidencias/rodada_01/`): app compilado para web, servido
  estático, dirigido por Playwright contra o backend local.
  - `demo-catalog.png` — catálogo, com a origem (`http://localhost:3010 · chave
    pk_7ae3848f124…`) visível no topo.
  - `demo-vitrine.png` — a vitrine renderizada: hero, card de features com
    ícones e divisor, formulário com os três controles, rodapé e a barra de
    procedência (`spec de 15/08 02:11 · etag "dj22v590…"`).
  - `demo-acao.png` — toque no botão do spec → `Ação recebida: "showMessage"
    {text: veio do spec}`.
- **Bateria automatizada**: 14 testes novos no app demo (envelope + kernel,
  cubits, render). Nada quebrou: editor 266, `sdui_core` 105, `sdui_flutter` 72.
  `flutter analyze` sem issues, `pnpm build`/`pnpm lint` verdes,
  `scripts/gates_guard.sh` limpo (estendido para cobrir o app novo).

## O que o consumo real revelou

Insumo priorizado, em ordem de urgência:

1. **`events` é dado inerte — falta o runtime (item 28).** O contrato funciona:
   o toque no botão entrega `SduiAction(type, params)` ao app. Mas não existe
   catálogo de ações nem executor, então **todo app cliente teria que escrever o
   seu**, e cada um inventaria um vocabulário diferente. Quanto mais specs forem
   criados antes disso, pior a migração.
2. **Nada muda depois que a tela carrega (item 29).** Todo texto da vitrine é
   literal no spec. Sem contexto de dados, o SDUI entrega layout, não conteúdo —
   e ninguém troca uma tela em produção sem republicar.
3. **`ETag` está pronto no servidor e ignorado pelo cliente.** Falta guardar o
   validador e reapresentá-lo — a peça mais barata do runtime do item 25, com o
   servidor já preparado.
4. **`specVersion` é uma bomba-relógio.** `parseContentSpec` recusa versão
   diferente da compilada no renderer. No editor isso é ótimo; num app publicado
   na loja, um spec novo derruba a tela **para sempre** (o usuário não atualiza o
   app). O runtime precisa de degradação elegante — o plano do item 25 já prevê
   isso em D5, e o consumo real confirma que é o cenário mais perigoso.
5. **`DrivaContent` continua stub.** Este app provou o caminho
   `fetch → parse → SduiView`; o package é esse caminho empacotado.
6. **Salvar publica.** É o VR-13-01: sem o item 24, editar no editor muda o app
   no próximo refresh, sem rede de proteção.

## Como testar

Backend local (Postgres do `backend/docker-compose.yml`):

```bash
cd backend && pnpm exec prisma migrate deploy && pnpm run build && pnpm run start:prod
docs/13-loop-sdui/evidencias/seed_vitrine.sh    # publica a vitrine e mostra a chave
docs/13-loop-sdui/evidencias/e2e_public.sh      # 17 PASS
```

App demo (o script descobre a chave sozinho):

```bash
cd apps/driva_demo_app && ./tool/run_demo.sh
```

Contra a homologação (depois do deploy deste PR no `develop`):

```bash
API=https://api-hml.driva.duckdns.org docs/13-loop-sdui/evidencias/seed_vitrine.sh
cd apps/driva_demo_app && API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
```

Prova de que é server-driven: com o app aberto, edite o conteúdo no editor,
salve, e toque em recarregar no app — a tela muda sem recompilar nada.

## Pendências assumidas

- Serve rascunho, não versão publicada (VR-13-01 → item 24).
- Chave sem rotação e sem rate limit (VR-13-03/04 → itens 25/26).
- Sem cache no cliente: toda abertura vai à rede.
- O app demo não executa ações (item 28).
