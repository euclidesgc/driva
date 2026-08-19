#!/usr/bin/env bash
# E2E — item 46 (projectId na rota do editor) / captura VISUAL automatizada
# (headless) CONTRA A HOMOLOGAÇÃO. O QA gera os prints; o dev humano só CONFERE.
#
# Sobe um Chrome headless com CDP e roda o e2e_drive.mjs, que executa na tela do
# hml o roteiro inteiro da §10 do plan.md — abrir pelo caminho normal, F5, aba
# anônima com o header da PRIMEIRA requisição, "ver no celular", breadcrumb, os
# três modos de falha e a alternância entre dois projetos — e assere o estado
# por API/CDP depois de cada passo.
#
# Aponta para o hml REAL (o mesmo artefato que o Coolify serve), nunca localhost
# — lição registrada do item 9g.
#
# Uso:
#   docs/46-projectid-na-rota-do-editor/e2e_shots.sh          # próxima rodada livre
#   docs/46-projectid-na-rota-do-editor/e2e_shots.sh 02       # em evidencias/rodada_02/
#
# Env (default = homologação):
#   WEB_BASE=https://hml.driva.duckdns.org
#   API_BASE=https://api-hml.driva.duckdns.org/v1
#   PROJ_A_ID=qyk9xbclx0moxwno3wplb4u9   (Portal da RE — ≠ default, exigência do DoD 24)
#   PROJ_B_ID=o8zw3ctaahlni0lhyqpes8f6   (E2E item 46 — projeto B)
#   GHOST_PROJECT=nao-existe-46
#
# Idempotente: o driver RESOLVE as fixtures em vez de recriá-las — projeto por
# id (com fallback por título, e criação se sumiu), conteúdo por slug dentro do
# projeto certo, sempre com uma CATEGORIA EXISTENTE escolhida na criação (R2d: o
# projeto default do hml não tem "Geral"). O spec dos dois conteúdos é
# carimbado com um marcador fixo, então rodar de novo devolve o mesmo estado.
#
# Auto-limpante quanto ao RASTRO DO DRIVER: o Chrome headless (pidfile), o
# --user-data-dir temporário (nunca um fixo — perfil fixo é a causa de meio
# diagnóstico errado de render), o contexto anônimo e a faixa de URL injetada no
# DOM. As DUAS FIXTURES DE CONTEÚDO FICAM DE PÉ de propósito: o passo 4b da §10
# é do humano, que precisa abrir o link do preview no aparelho depois que este
# script terminar. Apagá-las quebraria a entrega.
# NENHUMA mudança de código-fonte, NENHUM build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HERE="$ROOT/docs/46-projectid-na-rota-do-editor"
WEB_BASE="${WEB_BASE:-https://hml.driva.duckdns.org}"
API_BASE="${API_BASE:-https://api-hml.driva.duckdns.org/v1}"
PROJ_A_ID="${PROJ_A_ID:-qyk9xbclx0moxwno3wplb4u9}"
PROJ_B_ID="${PROJ_B_ID:-o8zw3ctaahlni0lhyqpes8f6}"
GHOST_PROJECT="${GHOST_PROJECT:-nao-existe-46}"
CDP_PORT="${SHOTS_CDP_PORT:-9226}"
ROUND="${1:-}"
CDPPID="$HERE/.e2e-shots-chrome.pid"
g=$'\e[32m'; r=$'\e[31m'; b=$'\e[1m'; d=$'\e[2m'; x=$'\e[0m'

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
[ -n "$CHROME" ] || { echo "${r}Chrome/Chromium não encontrado (a captura headless precisa dele).${x}"; exit 1; }
command -v node >/dev/null || { echo "${r}node ausente (o driver CDP precisa dele, Node 22+).${x}"; exit 1; }

if [ -z "$ROUND" ]; then
  last="$(ls -d "$HERE"/evidencias/rodada_* 2>/dev/null | sed 's#.*rodada_##' | sort -n | tail -1)"
  ROUND="$(printf '%02d' "$(( ${last:-0} + 1 ))")"
else
  ROUND="$(printf '%02d' "$((10#$ROUND))")"
fi
OUT="$HERE/evidencias/rodada_$ROUND"
mkdir -p "$OUT"

curl -sf -o /dev/null -H "x-project-id: $PROJ_A_ID" "$API_BASE/contents?limit=1" \
  || { echo "${r}API do hml não respondeu em $API_BASE — abortando.${x}"; exit 1; }
curl -sf -o /dev/null "$WEB_BASE/" \
  || { echo "${r}Editor do hml não respondeu em $WEB_BASE — abortando.${x}"; exit 1; }

echo ""
echo "${b}E2E do item 46 na tela do hml → evidencias/rodada_$ROUND/${x}"
echo "${d}WEB=$WEB_BASE  API=$API_BASE${x}"
echo "${d}PROJ_A=$PROJ_A_ID  PROJ_B=$PROJ_B_ID  fantasma=$GHOST_PROJECT${x}"

PROFILE="$(mktemp -d)"
"$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1600,1000 \
  --remote-debugging-port="$CDP_PORT" --user-data-dir="$PROFILE" about:blank \
  >/dev/null 2>&1 & echo $! > "$CDPPID"
trap 'kill "$(cat "$CDPPID" 2>/dev/null)" 2>/dev/null || true; rm -f "$CDPPID"; sleep 1; rm -rf "$PROFILE" 2>/dev/null || true' EXIT

i=0; until curl -sf -o /dev/null "http://localhost:$CDP_PORT/json/version"; do i=$((i+1)); [ "$i" -ge 40 ] && { echo "${r}Chrome CDP não subiu${x}"; exit 1; }; sleep 0.3; done

set +e
WEB_BASE="$WEB_BASE" API_BASE="$API_BASE" OUT="$OUT" CDP_PORT="$CDP_PORT" \
  PROJ_A_ID="$PROJ_A_ID" PROJ_B_ID="$PROJ_B_ID" GHOST_PROJECT="$GHOST_PROJECT" \
  node "$HERE/e2e_drive.mjs" 2>&1 | tee "$OUT/resultado.txt"
STATUS="${PIPESTATUS[0]}"
set -e

cp "$HERE/e2e_drive.mjs" "$HERE/e2e_shots.sh" "$OUT/" 2>/dev/null || true

echo ""
if [ "$STATUS" -eq 0 ]; then
  echo "${g}${b}Prints + README.md + resultado.txt salvos em $OUT${x}"
  echo "${d}Comece pelo README: o passo 4 (\"ver no celular\") é o aceite que carrega o item.${x}"
else
  echo "${r}${b}O driver falhou — veja $OUT/resultado.txt e os prints da rodada.${x}"
fi
exit "$STATUS"
