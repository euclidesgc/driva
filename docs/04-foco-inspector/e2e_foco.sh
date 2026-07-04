#!/usr/bin/env bash
# E2E — Foco no Inspector / captura VISUAL automatizada (headless).
# Prova que digitar num campo de propriedade NÃO perde mais o foco a cada tecla.
# O QA gera os prints; o dev só CONFERE. Exige o backend no ar em :3000
# (suba antes: docs/02-conteudos/e2e.sh).
#
# Uso:
#   docs/02-conteudos/e2e.sh                 # sobe Postgres efêmero + backend
#   docs/04-foco-inspector/e2e_foco.sh 01    # captura em evidencias/rodada_01/
#   docs/02-conteudos/e2e.sh down            # derruba a stack
#
# IMPORTANTE: rebuilda o web SEMPRE (SHOTS_REBUILD embutido) — o print tem de
# refletir o código ATUAL da branch (o fix), não um build velho.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE="http://localhost:3000/v1"
PROJECT="default"
WEB="$ROOT/apps/driva_editor"
BUILD="$WEB/build/web"
PORT="${SHOTS_PORT:-8901}"
HOST="http://localhost:$PORT"
HERE="$ROOT/docs/04-foco-inspector"
ROUND="${1:-}"
SRVPID="$HERE/.e2e-shots-server.pid"
CDPPID="$HERE/.e2e-shots-chrome.pid"
g=$'\e[32m'; r=$'\e[31m'; b=$'\e[1m'; d=$'\e[2m'; x=$'\e[0m'

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)"
[ -n "$CHROME" ] || { echo "${r}Chrome/Chromium não encontrado.${x}"; exit 1; }
command -v node >/dev/null || { echo "${r}node ausente (driver de interação precisa dele).${x}"; exit 1; }

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

if [ ! -f "$BUILD/index.html" ] || [ "${SHOTS_REBUILD:-1}" = "1" ]; then
  echo "${b}Build web (dev · com o fix)…${x}"
  ( cd "$WEB" && flutter build web --release --target lib/main_dev.dart \
      --dart-define-from-file=config/dev.json >/dev/null )
else
  echo "${d}Reusando build existente (SHOTS_REBUILD=0).${x}"
fi

# servidor estático com SPA fallback (deep links do path strategy)
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
        self.path = '/index.html'
        return super().do_GET()
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
PY
python3 "$SPA" "$BUILD" "$PORT" & echo $! > "$SRVPID"
trap 'for p in "$SRVPID" "$CDPPID"; do kill "$(cat "$p" 2>/dev/null)" 2>/dev/null || true; rm -f "$p"; done; rm -f "$SPA"' EXIT
i=0; until curl -sf -o /dev/null "$HOST/"; do i=$((i+1)); [ "$i" -ge 20 ] && { echo "${r}servidor estático não subiu${x}"; exit 1; }; sleep 0.3; done

echo ""
echo "${b}Interação (CDP headless): digitar '10' char-a-char no campo do Inspector${x}"
CDP_PORT="${SHOTS_CDP_PORT:-9224}"
"$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
  --remote-debugging-port="$CDP_PORT" --user-data-dir="$(mktemp -d)" about:blank \
  >/dev/null 2>&1 & echo $! > "$CDPPID"
i=0; until curl -sf -o /dev/null "http://localhost:$CDP_PORT/json/version"; do i=$((i+1)); [ "$i" -ge 30 ] && { echo "${r}Chrome CDP não subiu${x}"; break; }; sleep 0.3; done

WEB_BASE="$HOST" API_BASE="$BASE" PROJECT="$PROJECT" OUT="$OUT" CDP_PORT="$CDP_PORT" \
  FIELD_X="${FIELD_X:-1230}" FIELD_Y="${FIELD_Y:-250}" \
  node "$HERE/e2e_drive_foco.mjs" || echo "${r}driver falhou (veja acima)${x}"
kill "$(cat "$CDPPID" 2>/dev/null)" 2>/dev/null || true; rm -f "$CDPPID"

# relatório em markdown
{
  echo "# Rodada $ROUND — E2E visual (Foco no Inspector)"
  echo
  echo "> Prints headless gerados pelo QA. O dev só confere. Bug: digitar numa"
  echo "> propriedade perdia o foco a cada tecla (só o 1º dígito colava)."
  echo
  for row in \
    "01_editor_inspector|Editor aberto|/contents/:id/edit; Inspector do root column à direita, com 'Espaço entre filhos'." \
    "02_campo_focado|Campo focado|Clique no campo numérico 'Espaço entre filhos' — cursor ativo." \
    "03_valor_10|Digitou '10'|Após digitar 1 e 0 char-a-char, o campo mostra '10' (foco NÃO caiu — antes só '1' colava)." \
    "04_valor_105|Digitou '105'|Terceiro dígito acumula: '105'. Prova definitiva de foco contínuo."; do
    IFS='|' read -r file title desc <<< "$row"
    [ -s "$OUT/$file.png" ] || continue
    echo "### $title"; echo "$desc"; echo; echo "![$title]($file.png)"; echo
  done
} > "$OUT/README.md"

echo ""
echo "${g}${b}Prints + README.md salvos em $OUT${x}"
