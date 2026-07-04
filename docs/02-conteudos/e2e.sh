#!/usr/bin/env bash
# E2E — Conteúdos. Automatiza TUDO que dá para automatizar: sobe a stack local
# (Postgres de teste efêmero + backend), valida todo o contrato do backend via
# API e limpa o próprio rastro. Só o teste VISUAL da UI (que exige olho humano)
# fica manual, como checklist curto no fim.
#
# Uso:
#   docs/02-conteudos/e2e.sh          sobe a stack, valida a API, deixa no ar p/ o teste visual
#   docs/02-conteudos/e2e.sh down     encerra o backend + destrói o Postgres de teste
#
# Determinístico e idempotente: o Postgres de teste é RECRIADO LIMPO a cada run
# (docker compose down -v), então o schema nasce do zero e não há dado a perder.
# Rastro (tudo rastreável/removível — ver "down"): o processo do backend
# (pidfile .e2e-backend.pid), o log (.e2e-backend.log) e o container/volume
# driva-postgres. NENHUMA mudança de código-fonte.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE="http://localhost:3000/v1"
PROJECT="e2e-conteudos"
PROJECT2="e2e-conteudos-b"
HERE="$ROOT/docs/02-conteudos"
PIDFILE="$HERE/.e2e-backend.pid"
LOGFILE="$HERE/.e2e-backend.log"
BODYFILE="$(mktemp)"
STATUS=""; BODY=""; PASS=0; FAIL=0
g=$'\e[32m'; r=$'\e[31m'; b=$'\e[1m'; d=$'\e[2m'; x=$'\e[0m'

trap 'rm -f "$BODYFILE"' EXIT

jget() { python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    for k in sys.argv[1:]:
        d = d[int(k)] if isinstance(d, list) else d[k]
    print(d)
except Exception:
    print("<missing>")
' "$@"; }

api() { # method path [json] [project]
  local method="$1" path="$2" data="${3:-}" project="${4:-$PROJECT}"
  local -a args=(-s -o "$BODYFILE" -w '%{http_code}' -X "$method" "$BASE$path" -H "x-project-id: $project")
  [ -n "$data" ] && args+=(-H 'content-type: application/json' -d "$data")
  STATUS="$(curl "${args[@]}")"
  BODY="$(cat "$BODYFILE")"
}

check() { # desc expected actual
  if [ "$2" = "$3" ]; then printf "  ${g}✓${x} %s\n" "$1"; PASS=$((PASS+1))
  else printf "  ${r}✗ %s${x}  ${d}(esperado: %s | obtido: %s)${x}\n" "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}

check_re() { # desc regex actual
  if printf '%s' "$3" | grep -Eq "$2"; then printf "  ${g}✓${x} %s\n" "$1"; PASS=$((PASS+1))
  else printf "  ${r}✗ %s${x}  ${d}(regex: %s | obtido: %s)${x}\n" "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}

teardown_stack() {
  [ -f "$PIDFILE" ] && { kill "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; }
  rm -f "$LOGFILE"
  ( cd "$ROOT/backend" && docker compose down -v >/dev/null 2>&1 ) || true
  echo "Stack encerrada: backend parado e Postgres de teste destruído."
}

backend_alive() { curl -sf -o /dev/null "$BASE/contents" -H "x-project-id: $PROJECT" 2>/dev/null; }

if [ "${1:-}" = "down" ]; then teardown_stack; exit 0; fi

# ---------- preflight ----------
for cmd in docker curl python3 pnpm; do
  command -v "$cmd" >/dev/null || { echo "${r}falta o comando: $cmd${x}"; exit 1; }
done

echo "${b}E2E Conteúdos — subindo a stack local (Postgres de teste efêmero)${x}"

# encerra um backend de uma execução anterior deste script, se houver
[ -f "$PIDFILE" ] && { kill "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; sleep 1; }

# ---------- Postgres: recriado LIMPO a cada run (base vazia → db push sem perda) ----------
( cd "$ROOT/backend" && {
    if ! docker compose down -v >/dev/null 2>&1; then
      echo "  ${r}aviso: 'docker compose down -v' falhou — a base pode NÃO estar limpa (verifique docker/volumes)${x}"
    fi
    docker compose up -d >/dev/null
  } )
i=0; until docker exec driva-postgres pg_isready -U driva >/dev/null 2>&1; do
  i=$((i+1)); [ "$i" -ge 30 ] && { echo "${r}Postgres não respondeu${x}"; exit 1; }; sleep 1
done
echo "  Postgres no ar (driva-postgres:5433, base limpa)"

# ---------- backend ----------
if backend_alive; then
  echo "${r}Porta 3000 ocupada por outro processo — rode 'docs/02-conteudos/e2e.sh down' ou libere a porta.${x}"; exit 1
fi
[ -f "$ROOT/backend/.env" ] || { cp "$ROOT/backend/.env.example" "$ROOT/backend/.env"; echo "  ${d}criei backend/.env a partir do .env.example${x}"; }
[ -d "$ROOT/backend/node_modules" ] || ( cd "$ROOT/backend" && pnpm install --frozen-lockfile >/dev/null )
# base vazia: db push cria o schema do zero — sem flag destrutiva, sem perda de dado
( cd "$ROOT/backend" && pnpm prisma:generate >/dev/null && pnpm prisma db push --skip-generate >/dev/null && pnpm build >/dev/null )
( set -a; . "$ROOT/backend/.env"; set +a; cd "$ROOT/backend" && exec node dist/main.js ) >"$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"
i=0; until backend_alive; do i=$((i+1)); [ "$i" -ge 60 ] && { echo "${r}backend não subiu — veja $LOGFILE${x}"; exit 1; }; sleep 1; done
echo "  backend no ar em :3000 (pid $(cat "$PIDFILE"))"

# ---------- contrato do backend ----------
echo ""
echo "${b}Contrato do backend (/v1/contents)${x}"

api POST /contents '{"name":"Home","slug":"home","description":"Vitrine"}'
check "POST cria conteúdo (201)" 201 "$STATUS"
ID="$(printf '%s' "$BODY" | jget id)"
check "slug ecoado no summary" home "$(printf '%s' "$BODY" | jget slug)"
check_re "id novo é CUID2 (sem hífens, começa com letra)" '^[a-z][a-z0-9]{20,}$' "$ID"

api GET "/contents/$ID"
check "GET :id (200)" 200 "$STATUS"
check "envelope kind = content" content "$(printf '%s' "$BODY" | jget spec kind)"
check "envelope slug = home" home "$(printf '%s' "$BODY" | jget spec slug)"
check "envelope spec.id = id do registro" "$ID" "$(printf '%s' "$BODY" | jget spec id)"
check "root é column" column "$(printf '%s' "$BODY" | jget spec root type)"
check "envelope SEM screenTarget" False "$(printf '%s' "$BODY" | python3 -c "import sys,json;print('screenTarget' in json.load(sys.stdin)['spec'])" 2>/dev/null || echo ERRO)"

api POST /contents '{"name":"Home de novo","slug":"home"}'
check "slug repetido no projeto → 409" 409 "$STATUS"
check "409 devolve suggestedSlug=home-2" home-2 "$(printf '%s' "$BODY" | jget suggestedSlug)"

api POST /contents '{"name":"Home","slug":"home"}' "$PROJECT2"
check "slug igual em OUTRO projeto coexiste (201)" 201 "$STATUS"

api POST /contents '{"name":"Invalido","slug":"Bad Slug"}'
check "slug fora do formato → 400" 400 "$STATUS"

api PUT "/contents/$ID" '{"name":"Home v2"}'
check "PUT atualiza (200)" 200 "$STATUS"

api GET /contents
check "GET lista contém o id criado" yes "$(printf '%s' "$BODY" | python3 -c "import sys,json;print('yes' if any(c['id']=='$ID' for c in json.load(sys.stdin)) else 'no')" 2>/dev/null || echo no)"

api DELETE "/contents/$ID"
check "DELETE remove (204)" 204 "$STATUS"
api GET "/contents/$ID"
check "GET após delete → 404" 404 "$STATUS"

# ---------- resumo ----------
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "${g}${b}Contrato do backend: $PASS/$PASS OK.${x}"
else
  echo "${r}${b}Contrato do backend: $FAIL falha(s) de $((PASS+FAIL)).${x}  Veja acima — pode ser bug real."
fi

echo ""
echo "${b}Falta só o VISUAL (o que a API não enxerga). Com a stack no ar, rode o editor:${x}"
echo "  ${d}flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart \\"
echo "    --dart-define-from-file=apps/driva_editor/config/dev.json${x}"
echo "E confirme na tela (projeto 'default', lista começa vazia):"
echo "  1. A URL abre em /contents ${b}sem #${x} (path strategy)."
echo "  2. Em 'Novo conteúdo', digitar o Nome ${b}deriva o Slug ao vivo${x} no campo."
echo "  3. O card mostra o ${b}slug em destaque${x} + o ${b}\"ID de suporte\"${x}."
echo "  4. Criar dois 'Home': o 2º ${b}reabre o diálogo com 'home-2'${x} e a msg de slug em uso."
echo "  5. Arrastar um widget → preview renderiza; ${b}Ctrl+S${x} → 'Salvo'; ${b}F5${x} mantém."
echo "  6. Acessar /contents/nao-existe/edit → ${b}tela de NotFound tratada${x} (sem crash)."
echo ""
echo "${d}Ao terminar o visual: docs/02-conteudos/e2e.sh down  (para o backend e destrói o Postgres de teste).${x}"

[ "$FAIL" -eq 0 ] || exit 1
