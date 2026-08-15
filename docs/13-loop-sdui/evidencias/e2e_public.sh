#!/usr/bin/env bash
# E2E de contrato da API pública de consumo (roadmap 25, fatia da API).
# Roda contra qualquer ambiente; cria o próprio conteúdo de teste e o remove.
#
#   ./e2e_public.sh
#   API=https://api-hml.driva.duckdns.org ./e2e_public.sh
set -uo pipefail

API="${API:-http://localhost:3000}"
PROJECT="${PROJECT:-default}"
SLUG="e2e-public-$$"
PASS=0
FAIL=0

check() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "  PASS  $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  $label — esperado [$expected], veio [$actual]"
  fi
}

status() { curl -sS -o /dev/null -w '%{http_code}' "$@"; }

echo "API=$API  projeto=$PROJECT"

KEY=$(curl -sS "$API/v1/projects" | python3 -c "
import sys, json
rows = [r for r in json.load(sys.stdin) if r['id'] == '$PROJECT']
print(rows[0]['publishableKey'] if rows else '')
")
if [ -z "$KEY" ]; then
  echo "projeto '$PROJECT' não encontrado ou sem chave publicável"
  exit 1
fi
echo "chave publicável: ${KEY:0:14}…"

created=$(curl -sS -X POST "$API/v1/contents" \
  -H "x-project-id: $PROJECT" -H 'content-type: application/json' \
  -d '{"name":"E2E público","slug":"'"$SLUG"'"}')
id=$(echo "$created" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")

if [ -z "$id" ]; then
  echo "não consegui criar o conteúdo de teste: $created"
  exit 1
fi
echo "conteúdo de teste: $id ($SLUG)"

spec=$(python3 -c "
import json
print(json.dumps({'spec': {
  'specVersion': 1, 'kind': 'content', 'id': '$id',
  'name': 'E2E público', 'slug': '$SLUG',
  'root': {'id': 'n1', 'type': 'text', 'props': {'data': 'ok'}},
}}))
")
check "PUT spec" "200" "$(status -X PUT "$API/v1/contents/$id" \
  -H "x-project-id: $PROJECT" -H 'content-type: application/json' -d "$spec")"

body=$(curl -sS -D "/tmp/e2e_public_headers.$$" \
  -H "x-driva-key: $KEY" "$API/v1/public/contents/$SLUG")
headers=$(cat "/tmp/e2e_public_headers.$$")
etag=$(echo "$headers" | grep -i '^etag:' | sed 's/^[Ee][Tt][Aa][Gg]: //' | tr -d '\r')

check "GET por slug" "200" "$(status -H "x-driva-key: $KEY" "$API/v1/public/contents/$SLUG")"
check "devolve ETag" "sim" "$([ -n "$etag" ] && echo sim || echo nao)"
check "tem Cache-Control" "sim" \
  "$(echo "$headers" | grep -qi 'cache-control' && echo sim || echo nao)"
check "CORS liberado" "sim" \
  "$(echo "$headers" | grep -qi 'access-control-allow-origin: \*' && echo sim || echo nao)"
check "spec tem root" "text" \
  "$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin)['spec']['root']['type'])")"
check "slug bate" "$SLUG" \
  "$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin)['slug'])")"

check "revalidação 304" "304" \
  "$(status -H "x-driva-key: $KEY" -H "If-None-Match: $etag" "$API/v1/public/contents/$SLUG")"
check "etag velho volta 200" "200" \
  "$(status -H "x-driva-key: $KEY" -H 'If-None-Match: "obsoleto"' "$API/v1/public/contents/$SLUG")"

check "listagem pública" "200" "$(status -H "x-driva-key: $KEY" "$API/v1/public/contents")"
check "conteúdo aparece na lista" "sim" \
  "$(curl -sS -H "x-driva-key: $KEY" "$API/v1/public/contents" \
    | python3 -c "import sys,json; print('sim' if any(c['slug']=='$SLUG' for c in json.load(sys.stdin)['data']) else 'nao')")"

check "sem chave" "404" "$(status "$API/v1/public/contents/$SLUG")"
check "chave inválida" "404" \
  "$(status -H 'x-driva-key: pk_naoexiste' "$API/v1/public/contents/$SLUG")"
check "chave inválida na lista" "404" \
  "$(status -H 'x-driva-key: pk_naoexiste' "$API/v1/public/contents")"
check "slug inexistente" "404" \
  "$(status -H "x-driva-key: $KEY" "$API/v1/public/contents/nao-existe-$$")"
check "preflight OPTIONS" "204" "$(status -X OPTIONS "$API/v1/public/contents/$SLUG")"

curl -sS -o /dev/null -X DELETE "$API/v1/contents/$id" -H "x-project-id: $PROJECT"
rm -f "/tmp/e2e_public_headers.$$"
check "conteúdo removido some do público" "404" \
  "$(status -H "x-driva-key: $KEY" "$API/v1/public/contents/$SLUG")"

echo
echo "$PASS PASS / $FAIL FAIL"
[ "$FAIL" -eq 0 ]
