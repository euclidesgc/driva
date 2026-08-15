#!/usr/bin/env bash
# E2E de contrato — item 38 (destravar o construtor) CONTRA A HOMOLOGAÇÃO.
#
# A feature é quase toda interação de canvas; o que a API prova é a outra metade,
# a da D1: **todo estado que o construtor consegue produzir continua reabrindo**.
# Aqui exercitamos, por PUT/GET no spec real do hml, os quatro estados que o
# item 38 criou ou destravou — página vazia (sem `root`), raiz folha (o antigo
# beco), o resultado do wrap (`column[text, image]`) e o "Esvaziar conteúdo"
# (volta a ficar sem `root`) — e as duas cancelas estáticas do DoD (§11).
#
# Complementa o e2e_shots.sh, que dirige os gestos na TELA do hml e assere o spec
# depois de cada um. Juntos fecham o roteiro da §10 do plan.md.
#
# Idempotente e auto-limpante: purga qualquer rastro do slug $SLUG no começo e no
# fim. NUNCA toca conteúdo que não seja o dele. Rastro removível: um conteúdo de
# teste no projeto `default` do hml + um diretório temporário. Zero mudança de
# código-fonte.
#
# Requisitos: bash + curl + jq (+ git/grep para as cancelas estáticas). Uso:
#   docs/15-destravar-construtor/e2e_hml.sh
#   API_BASE=http://localhost:3000/v1 docs/15-destravar-construtor/e2e_hml.sh
#
# Saída: PASS/FAIL por checagem; exit 0 = tudo PASS.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_BASE="${API_BASE:-https://api-hml.driva.duckdns.org/v1}"
PROJECT="${PROJECT:-default}"
SLUG="${SLUG:-e2e-38-contrato}"
NAME="E2E 38 contrato"
TMP="$(mktemp -d)"
PASS=0; FAIL=0; FAILED=()
CREATED_ID=""

g=$'\033[32m'; r=$'\033[31m'; d=$'\033[2m'; o=$'\033[0m'
pass() { PASS=$((PASS+1)); printf '%sPASS%s %s\n' "$g" "$o" "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED+=("$1"); printf '%sFAIL%s %s\n' "$r" "$o" "$1"; [ -n "${2:-}" ] && printf '     %s%s%s\n' "$d" "$2" "$o"; }
check() { [ "$2" = "$3" ] && pass "$1" || fail "$1" "esperado=$2 obtido=$3 ${4:-}"; }
section() { printf '\n=== %s ===\n' "$1"; }

req() { # method path [curl-args...]
  local method="$1" path="$2"; shift 2
  HTTP_STATUS="$(curl -s -o "$TMP/body" -w '%{http_code}' -X "$method" "$API_BASE$path" \
    -H "x-project-id: $PROJECT" "$@")"
  HTTP_BODY="$(cat "$TMP/body")"
}
jqr() { printf '%s' "$HTTP_BODY" | jq -r "$@" 2>/dev/null; }

purge() {
  curl -s -H "x-project-id: $PROJECT" "$API_BASE/contents?q=E2E%2038&limit=100" \
    | jq -r --arg s "$SLUG" '.data[]? | select(.slug == $s) | .id' 2>/dev/null \
    | while read -r id; do
        [ -n "$id" ] && curl -s -o /dev/null -X DELETE "$API_BASE/contents/$id" -H "x-project-id: $PROJECT"
      done
}
cleanup() {
  purge
  [ -n "$CREATED_CATEGORY_ID" ] && curl -s -o /dev/null -X DELETE "$API_BASE/categories/$CREATED_CATEGORY_ID" -H "x-project-id: $PROJECT"
  rm -rf "$TMP"
}
trap cleanup EXIT

# O projeto `default` do hml não tem a categoria "Geral" que o backend usa como
# destino implícito, então o conteúdo de teste precisa apontar uma categoria: usa
# a primeira que existir e só cria (e apaga) uma se o projeto estiver sem nenhuma.
CREATED_CATEGORY_ID=""
resolve_category() {
  CATEGORY_ID="$(curl -s -H "x-project-id: $PROJECT" "$API_BASE/categories" | jq -r '.[0].id // empty')"
  if [ -z "$CATEGORY_ID" ]; then
    CATEGORY_ID="$(curl -s -X POST "$API_BASE/categories" -H "x-project-id: $PROJECT" \
      -H 'content-type: application/json' -d '{"name":"E2E 38"}' | jq -r '.id // empty')"
    CREATED_CATEGORY_ID="$CATEGORY_ID"
  fi
}

# spec <root-json|null> — o mesmo envelope que ContentSpec.toJson() emite
spec() {
  local root="$1"
  jq -nc --arg id "$CREATED_ID" --arg name "$NAME" --arg slug "$SLUG" --argjson root "$root" \
    '{specVersion:1, kind:"content", id:$id, name:$name, slug:$slug} + (if $root == null then {} else {root:$root} end)'
}

echo "Alvo: ${API_BASE}   projeto: ${PROJECT}   slug: ${SLUG}"
purge

section "0. cancelas estáticas do DoD (§11 do plan.md)"
if [ -d "$ROOT/.git" ]; then
  sources() { grep -rl --include='*.dart' --exclude-dir=build --exclude-dir=.dart_tool \
    "noSlotAvailable" "$ROOT/packages" "$ROOT/apps" 2>/dev/null; }
  check "0.1 DropRefusal.noSlotAvailable não existe mais no workspace" "0" "$(sources | wc -l | tr -d ' ')" \
    "$(sources | head -3 | tr '\n' ' ')"
  grep -q "SduiNode? wrapNode(" "$ROOT/packages/sdui_core/lib/src/ops/tree_ops.dart" \
    && pass "0.2 wrapNode existe no kernel" || fail "0.2 wrapNode existe no kernel"
  grep -q "class DropRequiresWrap" "$ROOT/packages/sdui_core/lib/src/ops/drop_ops.dart" \
    && pass "0.3 DropRequiresWrap existe no kernel" || fail "0.3 DropRequiresWrap existe no kernel"
else
  echo "${d}(fora de um checkout — cancelas estáticas puladas)${o}"
fi

section "1. hml no ar"
req GET "/contents?limit=1"
check "1.1 GET /contents -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "1.2 envelope {data,nextCursor}" "true" "$(jqr 'has("data") and has("nextCursor")')"

section "2. página vazia — o ponto de partida da §10 (conteúdo sem root)"
resolve_category
[ -n "$CATEGORY_ID" ] && pass "2.0 categoria de destino resolvida ($CATEGORY_ID)" || fail "2.0 categoria de destino resolvida"
req POST "/contents" -H 'content-type: application/json' \
  -d "$(jq -nc --arg n "$NAME" --arg s "$SLUG" --arg c "$CATEGORY_ID" '{name:$n, slug:$s, description:"E2E do item 38", categoryId:$c}')"
check "2.1 criar -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
CREATED_ID="$(jqr '.id')"
[ -n "$CREATED_ID" ] && [ "$CREATED_ID" != "null" ] && pass "2.2 id retornado ($CREATED_ID)" || { fail "2.2 id retornado" "body=$HTTP_BODY"; echo "sem id — abortando"; exit 1; }
req GET "/contents/$CREATED_ID"
check "2.3 GET /:id -> 200" "200" "$HTTP_STATUS"
check "2.4 spec nasce SEM root (página vazia)" "false" "$(jqr '.spec | has("root")')" "spec=$(jqr '.spec')"
check "2.5 specVersion = 1" "1" "$(jqr '.spec.specVersion')"

section "3. raiz folha — o estado que travava o construtor antes do item 38"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' \
  -d "$(jq -nc --argjson spec "$(spec '{"id":"nd_1","type":"text","props":{"data":"Texto"}}')" '{spec:$spec}')"
check "3.1 PUT raiz folha -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "3.2 root é o text (folha, sem slot livre)" "text" "$(jqr '.spec.root.type')"
check "3.3 folha não ganhou children" "false" "$(jqr '.spec.root | has("children")')"

section "4. o que o wrap produz reabre — column[text, image] (D1/D4)"
WRAPPED='{"id":"nd_9","type":"column","props":{},"children":[{"id":"nd_1","type":"text","props":{"data":"Texto"}},{"id":"nd_2","type":"image","props":{}}]}'
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' \
  -d "$(jq -nc --argjson spec "$(spec "$WRAPPED")" '{spec:$spec}')"
check "4.1 PUT agrupado -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "4.2 root virou column" "column" "$(jqr '.spec.root.type')"
check "4.3 o text virou filho, na ordem" "text" "$(jqr '.spec.root.children[0].type')"
check "4.4 o image entrou depois dele" "image" "$(jqr '.spec.root.children[1].type')"
check "4.5 a subárvore original ficou intacta (props preservadas)" "Texto" "$(jqr '.spec.root.children[0].props.data')"
check "4.6 round-trip byte-a-byte do que foi gravado" \
  "$(spec "$WRAPPED" | jq -S -c .)" "$(jqr '.spec | tostring' | jq -S -c 'fromjson' 2>/dev/null || jqr '.spec' | jq -S -c .)"

section "5. guarda de versão do spec (o documento gravado é sempre um spec)"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' \
  -d '{"spec":{"kind":"content","id":"x","name":"x","slug":"x"}}'
check "5.1 PUT spec sem specVersion -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "5.2 o spec bom continua lá (o 400 não gravou nada)" "column" "$(jqr '.spec.root.type')"

section "6. \"Esvaziar conteúdo\" na raiz (F6/D9) — volta a ser página vazia e reabre"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' \
  -d "$(jq -nc --argjson spec "$(spec null)" '{spec:$spec}')"
check "6.1 PUT sem root -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "6.2 spec sem root (esvaziado)" "false" "$(jqr '.spec | has("root")')"
check "6.3 nome e slug intactos" "$SLUG" "$(jqr '.spec.slug')"

section "7. limpeza"
req DELETE "/contents/$CREATED_ID"
check "7.1 DELETE -> 204" "204" "$HTTP_STATUS"
req GET "/contents/$CREATED_ID"
check "7.2 GET após delete -> 404" "404" "$HTTP_STATUS"
CREATED_ID=""

section "Resumo"
printf '%sPASS=%d%s  %sFAIL=%d%s\n' "$g" "$PASS" "$o" "$r" "$FAIL" "$o"
if [ "$FAIL" -gt 0 ]; then printf '%sFalhas:%s %s\n' "$r" "$o" "${FAILED[*]}"; exit 1; fi
echo "${g}Tudo verde contra ${API_BASE}.${o}"
