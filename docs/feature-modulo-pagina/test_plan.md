# Test Plan — Módulo Página (I1)

> Roteiro do teste E2E manual. Quem executa é o **dev**; prints em `evidencias/`. Dono: QA.

## Pré-condições

1. Postgres: `docker compose -f backend/docker-compose.yml up -d` (porta **5433**).
2. Backend: `cd backend && pnpm start:dev` (ou `node dist/main.js`) → `curl localhost:3000/v1/pages` responde.
3. Editor: `flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart --dart-define-from-file=apps/driva_editor/config/dev.json` (a partir de `apps/driva_editor`, use caminhos relativos).
   - Sem backend? Rode sem o `--dart-define-from-file`: entra em modo fake (dados em memória).

## Roteiro (numere os prints: `01-lista.png`, `02-nova-pagina.png`, ...)

| # | Passo | Observar | Print |
|---|---|---|---|
| 1 | Abrir o app | Lista de páginas carrega (ou estado vazio com CTA) | 01 |
| 2 | "Nova página" → nome "Home", tela "home" → Criar | Navega direto para o editor; top bar mostra nome + chip da tela; status "Salvo" | 02 |
| 3 | Arrastar `Container` da paleta para o canvas | Bloco aparece no preview; fica selecionado; inspector mostra os campos de Container | 03 |
| 4 | Com o container selecionado, clicar em `Text` na paleta | Texto entra DENTRO do container (slot único) | 04 |
| 5 | No inspector do texto: mudar "Texto", tamanho 22, cor `#E8602C` | Preview reflete cada mudança imediatamente; status vira "Não salvo" | 05 |
| 6 | Aba "Árvore": arrastar um bloco para reordenar | Ordem muda na árvore E no preview | 06 |
| 7 | Selecionar um bloco no PREVIEW (clique) | Contorno laranja + label com o nome do tipo; inspector acompanha | 07 |
| 8 | Trocar dispositivo (smartphone→tablet) e zoom | Moldura muda de dimensão; conteúdo re-renderiza | 08 |
| 9 | `Delete` com bloco selecionado | Bloco some; seleção limpa | 09 |
| 10 | `Ctrl+S` | Status: "Salvando…" → "Salvo" | 10 |
| 11 | F5 (recarregar o browser) e reabrir a página | Tudo como deixado (persistiu no Postgres) | 11 |
| 12 | `docker exec driva-postgres psql -U driva -c 'select id, name from pages;'` | A linha da página está lá | 12 |
| 13 | Derrubar o backend e tentar salvar | "Falha ao salvar" + documento intacto na tela | 13 |
| 14 | Abrir URL de página inexistente (`/pages/nao-existe/edit`) | Tela de erro tratada com volta à lista, sem crash | 14 |

## Casos de borda extras

- Página recém-criada é vazia → preview mostra a orientação "arraste um widget".
- Arrastar bloco para dentro da própria subárvore → nada acontece (guarda do kernel).
- Criar página com nome vazio → validação no diálogo.

## Instrumentação ativa (mapa da limpeza)

| Item | Onde | Status |
|---|---|---|
| Repositórios fake em memória (`FakePagesStore`) | `apps/driva_editor/lib/core/dev/` + fakes nos módulos | **Permanece** — é o modo dev sem backend, chaveado por config (`USE_FAKE_DATA`); não vai a produção (prod.json = false) |
| Entrypoints de verificação | `apps/driva_editor/test_driver/app.dart`, `app_backend.dart` | **Permanece** — alvos de dev/E2E, fora de `lib/` de produção |
| Log HTTP (Dio LogInterceptor) | `core/network/dio_client.dart` | **Permanece** — já condicionado ao flavor dev |

Nenhuma instrumentação descartável pendente de limpeza.
