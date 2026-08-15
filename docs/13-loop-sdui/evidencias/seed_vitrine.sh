#!/usr/bin/env bash
# Publica o conteúdo de vitrine (vitrine_spec.json) num ambiente do driva.
# Cria se não existir, atualiza se já existir — idempotente.
#
#   ./seed_vitrine.sh                                   # localhost:3000
#   API=https://api-hml.driva.duckdns.org ./seed_vitrine.sh
#   API=... PROJECT=meu-projeto ./seed_vitrine.sh
set -euo pipefail

API="${API:-http://localhost:3000}"
PROJECT="${PROJECT:-default}"
SLUG="vitrine-do-renderer"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPEC_FILE="$HERE/vitrine_spec.json"

echo "API=$API  projeto=$PROJECT"

existing=$(curl -sS "$API/v1/contents?q=$SLUG&limit=100" -H "x-project-id: $PROJECT" \
  | python3 -c "
import sys, json
rows = json.load(sys.stdin).get('data', [])
match = [r for r in rows if r['slug'] == '$SLUG']
print(match[0]['id'] if match else '')
")

if [ -z "$existing" ]; then
  echo "criando conteúdo..."
  existing=$(curl -sS -X POST "$API/v1/contents" \
    -H "x-project-id: $PROJECT" -H 'content-type: application/json' \
    -d '{"name":"Vitrine do renderer","slug":"'"$SLUG"'","description":"Conteúdo de demonstração do app cliente."}' \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
fi
echo "conteúdo: $existing"

payload=$(python3 -c "
import json
spec = json.load(open('$SPEC_FILE'))
spec['id'] = '$existing'
print(json.dumps({'spec': spec}))
")

curl -sS -o /dev/null -w "PUT spec → %{http_code}\n" -X PUT "$API/v1/contents/$existing" \
  -H "x-project-id: $PROJECT" -H 'content-type: application/json' -d "$payload"

key=$(curl -sS "$API/v1/projects" | python3 -c "
import sys, json
rows = [r for r in json.load(sys.stdin) if r['id'] == '$PROJECT']
print(rows[0]['publishableKey'] if rows else '')
")

curl -sS -o /dev/null -w "GET público → %{http_code}\n" \
  -H "x-driva-key: $key" "$API/v1/public/contents/$SLUG"

echo "pronto: $API/v1/public/contents/$SLUG"
echo "chave publicável do projeto: $key"
