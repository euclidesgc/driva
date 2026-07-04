#!/usr/bin/env bash
# E2E — Conteúdos / captura VISUAL automatizada (headless).
# O QA gera os prints; o dev humano só CONFERE. Roda DEPOIS do e2e.sh (que deixa
# o backend + Postgres de teste efêmero no ar) e ANTES do `e2e.sh down`.
#
# Uso:
#   docs/02-conteudos/e2e.sh            # sobe a stack (Postgres efêmero + backend)
#   docs/02-conteudos/e2e_shots.sh 03   # captura os prints em evidencias/rodada_03/
#   docs/02-conteudos/e2e.sh down       # derruba a stack
#
# Captura os estados VISUAIS alcançáveis por URL (o web usa path strategy, sem #):
#   01_lista_vazia          /contents                      (antes de semear)
#   02_lista_com_conteudos  /contents                      (após semear 'default')
#   03_editor_carregado     /contents/<id>/edit            (conteúdo real)
#   04_notfound             /contents/nao-existe/edit       (rota tratada)
# Estados que exigem interação dentro do canvas (digitar → slug ao vivo,
# drag-drop, reabrir diálogo com home-2) NÃO são captáveis por URL — ver o
# checklist no test_plan.md (precisam de flutter_driver, follow-up).
#
# Determinístico: o Postgres é efêmero (o e2e.sh o recria limpo), então 'default'
# nasce vazio. Rastro removível: servidor estático (pidfile) + build/web.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE="http://localhost:3000/v1"
PROJECT="default"                       # o projeto que o web (dev.json) lê
WEB="$ROOT/apps/driva_editor"
BUILD="$WEB/build/web"
PORT="${SHOTS_PORT:-8899}"
HOST="http://localhost:$PORT"
HERE="$ROOT/docs/02-conteudos"
ROUND="${1:-}"
SRVPID="$HERE/.e2e-shots-server.pid"
g=$'\e[32m'; r=$'\e[31m'; b=$'\e[1m'; d=$'\e[2m'; x=$'\e[0m'

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)"
[ -n "$CHROME" ] || { echo "${r}Chrome/Chromium não encontrado (headless screenshot precisa dele).${x}"; exit 1; }

# rodada: usa o arg (ex.: 03) ou calcula a próxima livre
if [ -z "$ROUND" ]; then
  last="$(ls -d "$HERE"/evidencias/rodada_* 2>/dev/null | sed 's#.*rodada_##' | sort -n | tail -1)"
  ROUND="$(printf '%02d' "$(( ${last:-0} + 1 ))")"
else
  ROUND="$(printf '%02d' "$((10#$ROUND))")"
fi
OUT="$HERE/evidencias/rodada_$ROUND"
mkdir -p "$OUT"

backend_alive() { curl -sf -o /dev/null "$BASE/contents" -H "x-project-id: $PROJECT" 2>/dev/null; }
backend_alive || { echo "${r}Backend não está no ar em :3000. Rode antes: docs/02-conteudos/e2e.sh${x}"; exit 1; }

# ---------- build web (reusa se já existe; SHOTS_REBUILD=1 força) ----------
if [ ! -f "$BUILD/index.html" ] || [ "${SHOTS_REBUILD:-0}" = "1" ]; then
  echo "${b}Build web (dev)…${x}"
  ( cd "$WEB" && flutter build web --release --target lib/main_dev.dart \
      --dart-define-from-file=config/dev.json >/dev/null )
fi

# ---------- servidor estático com SPA fallback (deep links do path strategy) ----------
SPA="$(mktemp)"
cat > "$SPA" <<'PY'
import http.server, os, sys
root, port = sys.argv[1], int(sys.argv[2])
os.chdir(root)
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split('?')[0].lstrip('/')
        if path and os.path.isfile(path):
            return super().do_GET()
        self.path = '/index.html'         # SPA fallback p/ rotas profundas
        return super().do_GET()
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
PY
python3 "$SPA" "$BUILD" "$PORT" & echo $! > "$SRVPID"
trap 'kill "$(cat "$SRVPID" 2>/dev/null)" 2>/dev/null || true; rm -f "$SRVPID" "$SPA"' EXIT
i=0; until curl -sf -o /dev/null "$HOST/"; do i=$((i+1)); [ "$i" -ge 20 ] && { echo "${r}servidor estático não subiu${x}"; exit 1; }; sleep 0.3; done

shot() { # nome url
  "$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
    --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
    --virtual-time-budget=20000 --screenshot="$OUT/$1.png" "$2" >/dev/null 2>&1
  [ -s "$OUT/$1.png" ] && printf "  ${g}✓${x} %s\n" "$1.png" || printf "  ${r}✗ %s (vazio)${x}\n" "$1.png"
}

seed() { # name slug [description]
  curl -s -o /dev/null -X POST "$BASE/contents" -H "x-project-id: $PROJECT" \
    -H 'content-type: application/json' \
    -d "{\"name\":\"$1\",\"slug\":\"$2\",\"description\":\"${3:-}\"}"
}

echo ""
echo "${b}Capturando prints → evidencias/rodada_$ROUND/${x}"

# 1) lista vazia (antes de semear)
shot 01_lista_vazia "$HOST/contents"

# 2) semeia 'default' e captura a lista com conteúdos
seed "Home"            "home"            "Vitrine da loja"
ID_HOME="$(curl -s "$BASE/contents" -H "x-project-id: $PROJECT" \
  | python3 -c "import sys,json;print(next((c['id'] for c in json.load(sys.stdin) if c['slug']=='home'),''))")"
seed "Promoções 2026"  "promocoes-2026"  "Campanha de inverno"
shot 02_lista_com_conteudos "$HOST/contents"

# 3) editor carregado num conteúdo real
[ -n "$ID_HOME" ] && shot 03_editor_carregado "$HOST/contents/$ID_HOME/edit" \
  || printf "  ${r}✗ 03_editor_carregado (sem id)${x}\n"

# 4) rota inexistente → NotFound tratado
shot 04_notfound "$HOST/contents/nao-existe/edit"

echo ""
echo "${g}${b}Prints salvos em $OUT${x}"
echo "${d}Confira as imagens. Estados de interação (slug ao vivo, drag-drop, diálogo home-2) seguem no checklist do test_plan.md.${x}"
