#!/usr/bin/env bash
# E2E — item 38 (destravar o construtor) / captura VISUAL automatizada (headless)
# CONTRA A HOMOLOGAÇÃO. O QA gera os prints; o dev humano só CONFERE.
#
# Sobe um Chrome headless com CDP e roda o e2e_drive.mjs, que executa os 12 passos
# do roteiro da §10 do plan.md na tela do hml — arrastar da paleta, soltar sobre
# nó, Ctrl+G, Ctrl+Z, selecionar — e **assere o spec por API depois de cada gesto**.
# Ao dev sobra conferir as imagens (cada uma descrita no README.md da rodada) e o
# único passo que máquina nenhuma pega: o Chrome não reagir ao Ctrl+G.
#
# Aponta para o hml REAL (o mesmo artefato que o Coolify serve), nunca localhost —
# lição registrada do item 9g.
#
# Uso:
#   docs/15-destravar-construtor/e2e_shots.sh          # próxima rodada livre
#   docs/15-destravar-construtor/e2e_shots.sh 01       # em evidencias/rodada_01/
#
# Env (default = homologação):
#   WEB_BASE=https://hml.driva.duckdns.org
#   API_BASE=https://api-hml.driva.duckdns.org/v1
#   PROJECT=default
#   SLUG=e2e-38-canvas
#
# Idempotente e auto-limpante: o driver cria UM conteúdo de teste (slug $SLUG) e o
# purga por API no começo E no fim. Nada mais é tocado em homologação. Rastro
# removível: o Chrome headless (pidfile) e um --user-data-dir temporário.
# NENHUMA mudança de código-fonte, NENHUM build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HERE="$ROOT/docs/15-destravar-construtor"
WEB_BASE="${WEB_BASE:-https://hml.driva.duckdns.org}"
API_BASE="${API_BASE:-https://api-hml.driva.duckdns.org/v1}"
PROJECT="${PROJECT:-default}"
SLUG="${SLUG:-e2e-38-canvas}"
CDP_PORT="${SHOTS_CDP_PORT:-9223}"
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

curl -sf -o /dev/null -H "x-project-id: $PROJECT" "$API_BASE/contents?limit=1" \
  || { echo "${r}API do hml não respondeu em $API_BASE — abortando.${x}"; exit 1; }
curl -sf -o /dev/null "$WEB_BASE/" \
  || { echo "${r}Editor do hml não respondeu em $WEB_BASE — abortando.${x}"; exit 1; }

echo ""
echo "${b}E2E do item 38 na tela do hml → evidencias/rodada_$ROUND/${x}"
echo "${d}WEB=$WEB_BASE  API=$API_BASE  projeto=$PROJECT  slug=$SLUG${x}"

PROFILE="$(mktemp -d)"
"$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
  --remote-debugging-port="$CDP_PORT" --user-data-dir="$PROFILE" about:blank \
  >/dev/null 2>&1 & echo $! > "$CDPPID"
trap 'kill "$(cat "$CDPPID" 2>/dev/null)" 2>/dev/null || true; rm -f "$CDPPID"; sleep 1; rm -rf "$PROFILE" 2>/dev/null || true' EXIT

i=0; until curl -sf -o /dev/null "http://localhost:$CDP_PORT/json/version"; do i=$((i+1)); [ "$i" -ge 30 ] && { echo "${r}Chrome CDP não subiu${x}"; exit 1; }; sleep 0.3; done

set +e
WEB_BASE="$WEB_BASE" API_BASE="$API_BASE" PROJECT="$PROJECT" SLUG="$SLUG" OUT="$OUT" CDP_PORT="$CDP_PORT" \
  node "$HERE/e2e_drive.mjs" 2>&1 | tee "$OUT/resultado.txt"
STATUS="${PIPESTATUS[0]}"
set -e

cp "$HERE/e2e_drive.mjs" "$HERE/e2e_shots.sh" "$HERE/e2e_hml.sh" "$OUT/" 2>/dev/null || true

echo ""
if [ "$STATUS" -eq 0 ]; then
  echo "${g}${b}Prints + README.md + resultado.txt salvos em $OUT${x}"
  echo "${d}Confira as imagens pelo README.md e depois rode o roteiro_e2e_humano.md (é curto).${x}"
else
  echo "${r}${b}O driver falhou — veja $OUT/resultado.txt e os prints da rodada.${x}"
fi
exit "$STATUS"
