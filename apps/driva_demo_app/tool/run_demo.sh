#!/usr/bin/env bash
# Sobe o app de demonstração já apontado para um ambiente do driva.
# Descobre a chave publicável do projeto na API (o editor a expõe em
# GET /v1/projects) e a injeta como dart-define — sem editar config à mão.
#
#   ./tool/run_demo.sh                                    # localhost:3000, 1º projeto
#   API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
#   DEVICE=chrome PROJECT_TITLE="Meu projeto" ./tool/run_demo.sh
set -euo pipefail

API="${API:-http://localhost:3000}"
DEVICE="${DEVICE:-chrome}"
PROJECT_TITLE="${PROJECT_TITLE:-}"

key=$(curl -sS "$API/v1/projects" | python3 -c "
import sys, json
rows = json.load(sys.stdin)
title = '''$PROJECT_TITLE'''.strip()
if title:
    rows = [r for r in rows if r['title'] == title]
if not rows:
    raise SystemExit('nenhum projeto encontrado' + (f' com título {title!r}' if title else ''))
print(rows[0]['publishableKey'])
")

echo "API=$API  chave=${key:0:14}…"

exec flutter run -d "$DEVICE" --target lib/main_dev.dart \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=PUBLISHABLE_KEY="$key"
