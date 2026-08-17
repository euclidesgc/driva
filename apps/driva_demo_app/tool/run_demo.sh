#!/usr/bin/env bash
# Sobe o app de demonstração num ambiente do driva (MODE=run) ou gera o APK
# release com a chave real embarcada (MODE=apk).
# Descobre a chave publicável do projeto na API (o editor a expõe em
# GET /v1/projects) e a injeta como dart-define — sem editar config à mão. Os
# config/<env>.json versionados trazem placeholder, então gerar release por
# --dart-define-from-file compila e falha em runtime com 404.
#
#   ./tool/run_demo.sh                                    # localhost:3000, 1º projeto
#   API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
#   DEVICE=chrome PROJECT_TITLE="Meu projeto" ./tool/run_demo.sh
#   MODE=apk TARGET=lib/main_hml.dart API=https://api-hml.driva.duckdns.org ./tool/run_demo.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MODE="${MODE:-run}"
API="${API:-http://localhost:3000}"
DEVICE="${DEVICE:-chrome}"
TARGET="${TARGET:-lib/main_dev.dart}"
PROJECT_TITLE="${PROJECT_TITLE:-}"

if [[ "$MODE" != run && "$MODE" != apk ]]; then
  echo "MODE desconhecido: '$MODE' (use run ou apk)" >&2
  exit 1
fi

if [[ "$MODE" == apk && "$API" == http://* ]]; then
  echo "MODE=apk com API em cleartext ($API): o targetSdk do app bloqueia http:// em release, e o APK sairia sem alcançar a API. Use https." >&2
  exit 1
fi

key=$(curl -sS "$API/v1/projects" | python3 -c "
import sys, json
rows = json.load(sys.stdin)
title = (sys.argv[1] if len(sys.argv) > 1 else '').strip()
if title:
    rows = [r for r in rows if r['title'] == title]
if not rows:
    raise SystemExit('nenhum projeto encontrado' + (f' com título {title!r}' if title else ''))
print(rows[0]['publishableKey'])
" "$PROJECT_TITLE")

if [[ "$key" != pk_* ]]; then
  echo "chave publicável inválida em $API: '${key:0:14}…'" >&2
  exit 1
fi

echo "MODE=$MODE  API=$API  TARGET=$TARGET  chave=${key:0:14}…"

case "$MODE" in
  run)
    exec flutter run -d "$DEVICE" --target "$TARGET" \
      --dart-define=API_BASE_URL="$API" \
      --dart-define=PUBLISHABLE_KEY="$key"
    ;;
  apk)
    flutter build apk --release --target "$TARGET" \
      --dart-define=API_BASE_URL="$API" \
      --dart-define=PUBLISHABLE_KEY="$key"
    echo "APK: $PWD/build/app/outputs/flutter-apk/app-release.apk"
    ;;
esac
