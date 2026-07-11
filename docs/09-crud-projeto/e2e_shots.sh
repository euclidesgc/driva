#!/usr/bin/env bash
# E2E — Projetos / captura VISUAL automatizada (headless) CONTRA A HOMOLOGAÇÃO.
# O QA gera os prints; o dev humano só CONFERE. Dirige o fluxo de Projetos na TELA
# (criar → abrir → arquivar → arquivados → excluir) via CDP e fotografa cada estado.
#
# Diferente do E2E de Conteúdos (docs/02, que sobe stack local), este aponta para o
# hml REAL — o mesmo artefato que o Coolify serve. De propósito: fecha o buraco de
# método que deixou as três quebras do #43 passarem (o E2E do 9d só bateu em
# localhost). Ver memória `e2e-precisa-exercitar-de-verdade`.
#
# Uso:
#   docs/09-crud-projeto/e2e_shots.sh          # captura na próxima rodada livre
#   docs/09-crud-projeto/e2e_shots.sh 01       # captura em evidencias/rodada_01/
#
# Env (default = homologação):
#   WEB_BASE=https://hml.driva.duckdns.org
#   API_BASE=https://api-hml.driva.duckdns.org/v1
#   TITLE="E2E 9g Projeto"
#
# Auto-limpante: o driver cria só um projeto de teste (título $TITLE) e o purga por
# API no começo e no fim. NUNCA toca o projeto `default`. Rastro removível: o Chrome
# headless (pidfile). NENHUMA mudança de código-fonte, NENHUM build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HERE="$ROOT/docs/09-crud-projeto"
WEB_BASE="${WEB_BASE:-https://hml.driva.duckdns.org}"
API_BASE="${API_BASE:-https://api-hml.driva.duckdns.org/v1}"
TITLE="${TITLE:-E2E 9g Projeto}"
CDP_PORT="${SHOTS_CDP_PORT:-9223}"
ROUND="${1:-}"
CDPPID="$HERE/.e2e-shots-chrome.pid"
g=$'\e[32m'; r=$'\e[31m'; b=$'\e[1m'; d=$'\e[2m'; x=$'\e[0m'

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
[ -n "$CHROME" ] || { echo "${r}Chrome/Chromium não encontrado (headless screenshot precisa dele).${x}"; exit 1; }
command -v node >/dev/null || { echo "${r}node ausente (o driver CDP precisa dele, Node 22+).${x}"; exit 1; }

# rodada: usa o arg (ex.: 01) ou calcula a próxima livre
if [ -z "$ROUND" ]; then
  last="$(ls -d "$HERE"/evidencias/rodada_* 2>/dev/null | sed 's#.*rodada_##' | sort -n | tail -1)"
  ROUND="$(printf '%02d' "$(( ${last:-0} + 1 ))")"
else
  ROUND="$(printf '%02d' "$((10#$ROUND))")"
fi
OUT="$HERE/evidencias/rodada_$ROUND"
mkdir -p "$OUT"

# pré-check: o hml está no ar?
curl -sf -o /dev/null "$API_BASE/projects?status=active" \
  || { echo "${r}API do hml não respondeu em $API_BASE — abortando.${x}"; exit 1; }

echo ""
echo "${b}Capturando prints do fluxo de Projetos (hml) → evidencias/rodada_$ROUND/${x}"
echo "${d}WEB=$WEB_BASE  API=$API_BASE${x}"

# Chrome headless com CDP, viewport 1366x900 (coordenadas do driver batem com isto)
"$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
  --remote-debugging-port="$CDP_PORT" --user-data-dir="$(mktemp -d)" about:blank \
  >/dev/null 2>&1 & echo $! > "$CDPPID"
trap 'kill "$(cat "$CDPPID" 2>/dev/null)" 2>/dev/null || true; rm -f "$CDPPID"' EXIT

i=0; until curl -sf -o /dev/null "http://localhost:$CDP_PORT/json/version"; do i=$((i+1)); [ "$i" -ge 30 ] && { echo "${r}Chrome CDP não subiu${x}"; exit 1; }; sleep 0.3; done

WEB_BASE="$WEB_BASE" API_BASE="$API_BASE" OUT="$OUT" CDP_PORT="$CDP_PORT" TITLE="$TITLE" \
  node "$HERE/e2e_drive.mjs" || { echo "${r}driver de captura falhou (veja acima)${x}"; exit 1; }

echo ""
echo "${g}${b}Prints salvos em $OUT${x}"
echo "${d}Confira as imagens — todo o fluxo criar→abrir→arquivar→excluir na tela do hml.${x}"
