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
#   01_lista_vazia          /contents                                    (antes de semear)
#   02_lista_com_conteudos  /contents                                    (após semear 'default')
#   03_editor_carregado     /projects/default/contents/<id>/edit         (conteúdo real)
#   04_notfound             /projects/default/contents/nao-existe/edit   (rota tratada)
#
# Os dois prints do editor passam por `shot_route`, não por `shot` direto: a URL é
# aberta antes num Chrome com CDP e só vira print se o roteamento do app tiver
# PARADO nela. Sem essa cerca, uma rota que deixe de existir cai na home pelo
# onException e o print sai bonito com a legenda errada — o script "passaria"
# fotografando outra tela.
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
CDPPID="$HERE/.e2e-shots-chrome.pid"
CDP_PORT="${SHOTS_CDP_PORT:-9223}"
ROUTE_SETTLE="${SHOTS_ROUTE_SETTLE:-8}"
FAILURES=0
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
trap 'for p in "$SRVPID" "$CDPPID"; do kill "$(cat "$p" 2>/dev/null)" 2>/dev/null || true; rm -f "$p"; done; rm -f "$SPA"' EXIT
i=0; until curl -sf -o /dev/null "$HOST/"; do i=$((i+1)); [ "$i" -ge 20 ] && { echo "${r}servidor estático não subiu${x}"; exit 1; }; sleep 0.3; done

# ---------- Chrome com CDP: dirige as interações E prova a rota dos prints ----------
"$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
  --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
  --remote-debugging-port="$CDP_PORT" --user-data-dir="$(mktemp -d)" about:blank \
  >/dev/null 2>&1 & echo $! > "$CDPPID"
CDP_UP=1
i=0; until curl -sf -o /dev/null "http://127.0.0.1:$CDP_PORT/json/version"; do
  i=$((i+1)); [ "$i" -ge 30 ] && { echo "${r}Chrome CDP não subiu${x}"; CDP_UP=0; break; }; sleep 0.3
done

fail() { # mensagem
  printf "  ${r}✗ %s${x}\n" "$1"
  FAILURES=$((FAILURES + 1))
}

shot() { # nome url
  "$CHROME" --headless=new --no-sandbox --disable-gpu --use-gl=swiftshader \
    --hide-scrollbars --force-device-scale-factor=1 --window-size=1366,900 \
    --virtual-time-budget=20000 --screenshot="$OUT/$1.png" "$2" >/dev/null 2>&1
  if [ -s "$OUT/$1.png" ]; then printf "  ${g}✓${x} %s\n" "$1.png"; else fail "$1.png (vazio)"; fi
}

cdp_open() { # url -> id do target aberto nela
  local body
  body="$(curl -s -X PUT "http://127.0.0.1:$CDP_PORT/json/new?$1" || true)"
  case "$body" in *'"id"'*) ;; *) body="$(curl -s "http://127.0.0.1:$CDP_PORT/json/new?$1" || true)" ;; esac
  case "$body" in *'"id"'*) ;; *) return 0 ;; esac
  printf '%s' "$body" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])"
}

cdp_close() { curl -s -o /dev/null "http://127.0.0.1:$CDP_PORT/json/close/$1" || true; }

resolved_path() { # url -> pathname em que o roteamento do app parou (vazio = não deu p/ saber)
  local tid path
  tid="$(cdp_open "$1" || true)"
  [ -n "$tid" ] || return 0
  sleep "$ROUTE_SETTLE"
  path="$(curl -s "http://127.0.0.1:$CDP_PORT/json" | python3 -c \
    "import sys,json,urllib.parse as u
alvo=[t for t in json.load(sys.stdin) if t.get('id')==sys.argv[1]]
print(u.urlparse(alvo[0]['url']).path if alvo else '')" "$tid" || true)"
  cdp_close "$tid"
  printf '%s' "$path"
}

shot_route() { # nome path — só fotografa se o app tiver PARADO no path pedido
  local resolved
  if [ "$CDP_UP" != "1" ]; then
    fail "$1 — sem Chrome CDP não dá para provar que o print é da tela certa"
    return
  fi
  resolved="$(resolved_path "$HOST$2" || true)"
  if [ "$resolved" != "$2" ]; then
    fail "$1 — a rota não casou: o app parou em '${resolved:-?}', não em '$2' (o print seria de outra tela)"
    return
  fi
  shot "$1" "$HOST$2"
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
if [ -n "$ID_HOME" ]; then
  shot_route 03_editor_carregado "/projects/$PROJECT/contents/$ID_HOME/edit"
else
  fail "03_editor_carregado (sem id)"
fi

# 4) conteúdo inexistente NAQUELE projeto → NotFound tratado.
# A API tem de confirmar o 404 antes: se 'nao-existe' passasse a existir, o print
# seria de um editor carregado com a legenda de tela de erro.
NOTFOUND_STATUS="$(curl -s -o /dev/null -w '%{http_code}' \
  "$BASE/contents/nao-existe" -H "x-project-id: $PROJECT")"
if [ "$NOTFOUND_STATUS" = "404" ]; then
  shot_route 04_notfound "/projects/$PROJECT/contents/nao-existe/edit"
else
  fail "04_notfound — a API devolveu $NOTFOUND_STATUS para 'nao-existe' (o print não provaria NotFound)"
fi

# ---------- estados de INTERAÇÃO (dirigidos por CDP; precisa de node) ----------
if [ "$CDP_UP" = "1" ] && command -v node >/dev/null; then
  echo ""
  echo "${b}Interações (CDP headless): slug ao vivo, colisão→home-2, drag-drop→salvar${x}"
  WEB_BASE="$HOST" API_BASE="$BASE" PROJECT="$PROJECT" OUT="$OUT" CDP_PORT="$CDP_PORT" \
    node "$HERE/e2e_drive.mjs" || fail "driver de interação falhou (veja acima)"
else
  fail "estados de interação não capturados (node ausente ou Chrome CDP fora do ar)"
fi

# ---------- relatório em markdown (imagem + o que cada uma testa) ----------
{
  echo "# Rodada $ROUND — E2E visual (Conteúdos)"
  echo
  echo "> Prints gerados pelo QA (headless). O dev só confere. Backend validado à parte pelo \`e2e.sh\`."
  echo
  for row in \
    "01_lista_vazia|Lista vazia|Rota /contents sem #; empty state com ícone, textos e CTA (ContentListEmpty)." \
    "02_lista_com_conteudos|Lista com conteúdos|Cards: slug em destaque + ID de suporte (CUID2); ContentListLoaded." \
    "03_editor_carregado|Editor carregado|/projects/:projectId/contents/:id/edit; paleta (ícones), canvas com device, inspector." \
    "04_notfound|NotFound tratado|/projects/:projectId/contents/nao-existe/edit → tela de erro amigável, sem crash." \
    "05_slug_ao_vivo|Slug derivado ao vivo|Digitar o Nome deriva o slug em tempo real (sanitização + validação)." \
    "06_colisao_home2|Colisão de slug → home-2|Slug repetido auto-resolve para home-2 (409 + suggestedSlug)." \
    "07_drag_preview|Drag-drop → preview|Arrastar Text da paleta → preview renderiza + inspector abre." \
    "08_salvo|Salvar → Salvo|Após Salvar, indicador muda para \"Salvo\"."; do
    IFS='|' read -r file title desc <<< "$row"
    [ -s "$OUT/$file.png" ] || continue
    echo "### $title"; echo "$desc"; echo; echo "![$title]($file.png)"; echo
  done
} > "$OUT/README.md"

echo ""
echo "${g}${b}Prints + README.md salvos em $OUT${x}"
echo "${d}Confira as imagens (o README.md descreve cada uma). Nenhum clique manual necessário.${x}"

if [ "$FAILURES" -gt 0 ]; then
  echo ""
  echo "${r}${b}$FAILURES print(s) não puderam ser provados — veja os ✗ acima.${x}"
  echo "${d}Um print que não passou pela cerca NÃO é evidência: não o leve para o final_report.${x}"
  exit 1
fi
