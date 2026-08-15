#!/usr/bin/env bash
#
# Guard-script dos Gates de qualidade (rede de segurança automática do CI).
# bash + grep puro, ZERO dependência Dart — cobre o que é mecanicamente
# detectável dos Gates 1 e 4. Os Gates 2 e 3 (tier de widget, arquivo gordo)
# são heurísticos demais para grep confiável e ficam no gate de revisão humano.
#
# Sai 0 se limpo, 1 se achar violação. Plugado no .github/workflows/ci.yml.
#
# Escapes pontuais (com justificativa) por comentário na própria linha:
#   // gate1-ok: <motivo>
#   // gate4-ok: <motivo>
#
# Isenções por caminho:
#   - core/theme/ (apps) e src/theme/ (sdui_flutter) são a FONTE dos tokens
#                               (Color(0x)/valores vivem aqui). A isenção é do
#                               caminho exato, não de qualquer pasta chamada
#                               "theme" — `presentation/theme/` do
#                               preferences_module continua sob os gates.
#   - test/                     testes podem usar literais.
#
# packages/sdui_flutter/ é isento do GATE 1, não do GATE 4:
#   - GATE 1: o renderer PRODUZ widgets por função (`type -> builder` é registry,
#             não anti-padrão), e `render`/`renderAll`/`renderFlexChildren` são a
#             API do renderer. Segue fora do gate automático.
#   - GATE 4: o styling derivado do spec vem do catálogo/props e não é literal —
#             mas o CHROME do renderer (estados do `image`, caixa de tipo
#             desconhecido) é nosso e mora em `src/theme/` desde o item 39. Sem
#             este gate, os tokens do pacote ficariam guardados só por revisão
#             humana.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET_LIBS=("apps/driva_editor/lib" "apps/driva_demo_app/lib")
GATE4_ONLY_LIBS=("packages/sdui_flutter/lib")
fail=0

# ----------------------------------------------------------------------------
# Coleta os arquivos-alvo, fora das pastas de tokens.
# ----------------------------------------------------------------------------
mapfile -t FILES < <(find "${TARGET_LIBS[@]}" -name '*.dart' | grep -v '/core/theme/' | sort)
mapfile -t GATE4_ONLY_FILES < <(find "${GATE4_ONLY_LIBS[@]}" -name '*.dart' | grep -v '/src/theme/' | sort)

emit() { # <GATE> <file:line> <trecho>
  printf '  [%s] %s\n      %s\n' "$1" "$2" "$3"
  fail=1
}

check_gate4() { # <file>
  local f="$1"
  while IFS=$'\t' read -r line content; do
    [ -z "${line:-}" ] && continue
    case "$content" in *"// gate4-ok"*) continue ;; esac
    emit "GATE4" "$f:$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')"
  done < <(grep -nE \
             'Color\(0x|\bColors\.[a-zA-Z]|fontSize: ?-?[0-9]|circular\( ?-?[0-9]|EdgeInsets\.(all|fromLTRB)\( ?-?[0-9]|EdgeInsets\.(symmetric|only)\([^)]*: ?-?[0-9]' "$f" \
             | grep -vE '\bColors\.(white|black|transparent)\b' \
             | sed -E 's/^([0-9]+):/\1\t/')
}

for f in "${GATE4_ONLY_FILES[@]}"; do
  check_gate4 "$f"
done

for f in "${FILES[@]}"; do
  # -------------------------------------------------------------------------
  # GATE 1 — nenhuma função/método que retorna Widget/List<Widget>.
  # Permitidos: build(), static pageBuilder(), e escape // gate1-ok.
  # (Callbacks itemBuilder/builder: são ARGUMENTOS, não declarações — não casam.)
  # -------------------------------------------------------------------------
  while IFS=$'\t' read -r line content; do
    [ -z "${line:-}" ] && continue
    case "$content" in
      *"Widget build("*|*"static Widget pageBuilder("*|*"// gate1-ok"*) continue ;;
    esac
    emit "GATE1" "$f:$line" "$(printf '%s' "$content" | sed 's/^[[:space:]]*//')"
  done < <(grep -nE '^[[:space:]]*(static )?(Widget|List<Widget>) _?[a-zA-Z0-9]+ ?\(' "$f" \
             | sed -E 's/^([0-9]+):/\1\t/')

  # -------------------------------------------------------------------------
  # GATE 4 — zero literal de estilo cru (deve vir de um theme/ via token).
  # Cobre: Color(0x…), Colors.<nome> (menos os primitivos white/black/transparent),
  # fontSize: <num>, (Border)Radius.circular(<num>), EdgeInsets.*(<num>).
  # Escape // gate4-ok libera a linha.
  # -------------------------------------------------------------------------
  check_gate4 "$f"
done

echo ""
if [ "$fail" -ne 0 ]; then
  echo "✗ gates_guard: violação(ões) acima. Tokenize (core/theme nos apps, src/theme no sdui_flutter) ou justifique com // gateN-ok: <motivo>."
  exit 1
fi
echo "✓ gates_guard: Gates 1 e 4 limpos em ${TARGET_LIBS[*]}; Gate 4 limpo em ${GATE4_ONLY_LIBS[*]}."
exit 0
