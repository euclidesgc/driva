#!/usr/bin/env bash
# E2E de contrato — fluxo Projetos CONTRA A HOMOLOGAÇÃO (não localhost).
#
# Smoke fim-a-fim do ciclo de vida de um projeto no hml REAL: criar (multipart) →
# aparece em ?status=active → GET :id → arquivar (sai de active, entra em archived,
# DELETE em ativo dá 409) → desarquivar → arquivar de novo → excluir (só arquivado).
# Idempotente e auto-limpante: cria um único projeto marcado com $TAG e o apaga no
# fim (arquiva→deleta). NUNCA toca a seed (`default`).
#
# Este é o complemento de contrato do e2e_shots.sh (que cobre o VISUAL na tela).
# Juntos fecham o buraco de método do #43: UI aberta + API batida no hml.
#
# Requisitos: bash + curl + jq. Uso:
#   docs/09-crud-projeto/e2e_hml.sh
#   BASE_URL=https://api.driva.duckdns.org/v1 docs/09-crud-projeto/e2e_hml.sh   # prod (cuidado)
#
# Saída: PASS/FAIL por checagem; exit 0 = tudo PASS.
set -u

BASE_URL="${BASE_URL:-https://api-hml.driva.duckdns.org/v1}"
TAG="e2e-hml-$(date +%s)-$$"
TMP="$(mktemp -d)"
PASS=0; FAIL=0; FAILED=()
CREATED_ID=""

g=$'\033[32m'; r=$'\033[31m'; d=$'\033[2m'; o=$'\033[0m'
pass() { PASS=$((PASS+1)); printf '%sPASS%s %s\n' "$g" "$o" "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED+=("$1"); printf '%sFAIL%s %s\n' "$r" "$o" "$1"; [ -n "${2:-}" ] && printf '     %s%s%s\n' "$d" "$2" "$o"; }
check() { [ "$2" = "$3" ] && pass "$1" || fail "$1" "esperado=$2 obtido=$3 ${4:-}"; }
section() { printf '\n=== %s ===\n' "$1"; }

# req: escreve status em HTTP_STATUS e corpo em HTTP_BODY
req() { # method url [curl-args...]
  local method="$1" url="$2"; shift 2
  HTTP_STATUS="$(curl -s -o "$TMP/body" -w '%{http_code}' -X "$method" "$BASE_URL$url" "$@")"
  HTTP_BODY="$(cat "$TMP/body")"
}
jqr() { printf '%s' "$HTTP_BODY" | jq -r "$@" 2>/dev/null; }

cleanup() {
  if [ -n "$CREATED_ID" ]; then
    curl -s -o /dev/null -X POST "$BASE_URL/projects/$CREATED_ID/archive" >/dev/null 2>&1
    curl -s -o /dev/null -X DELETE "$BASE_URL/projects/$CREATED_ID" >/dev/null 2>&1
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "Alvo: ${BASE_URL}   Tag: ${TAG}"

section "0. hml no ar"
req GET "/projects?status=active"
check "0.1 GET /projects?status=active -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "0.2 seed 'default' presente" "true" "$(jqr 'any(.[]; .id=="default")')"

section "1. criar projeto (multipart, sem imagem)"
req POST "/projects" -F "title=${TAG}-proj" -F "description=e2e hml"
check "1.1 criar -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
CREATED_ID="$(jqr '.id')"
[ -n "$CREATED_ID" ] && [ "$CREATED_ID" != "null" ] && pass "1.2 id retornado ($CREATED_ID)" || fail "1.2 id retornado" "body=$HTTP_BODY"
check "1.3 title ecoado" "${TAG}-proj" "$(jqr '.title')"
check "1.4 imageUrl null (sem imagem)" "null" "$(jqr '.imageUrl')"

section "2. aparece em active + GET :id"
req GET "/projects?status=active"
check "2.1 projeto criado listado em active" "true" "$(jqr --arg id "$CREATED_ID" 'any(.[]; .id==$id)')"
req GET "/projects/$CREATED_ID"
check "2.2 GET /:id -> 200" "200" "$HTTP_STATUS"
check "2.3 GET /:id categoria 'Geral' contabilizada" "1" "$(jqr '.categoryCount')"

section "3. arquivar (soft delete)"
req POST "/projects/$CREATED_ID/archive"
check "3.1 archive -> 200/201" "200" "$HTTP_STATUS" "obtido=$HTTP_STATUS body=$HTTP_BODY"
req GET "/projects?status=active"
check "3.2 sumiu de active" "false" "$(jqr --arg id "$CREATED_ID" 'any(.[]; .id==$id)')"
req GET "/projects?status=archived"
check "3.3 apareceu em archived" "true" "$(jqr --arg id "$CREATED_ID" 'any(.[]; .id==$id)')"

section "4. Restrict: DELETE em projeto ainda-ativo é barrado"
# desarquiva, tenta deletar ativo (deve 409), rearquiva
req POST "/projects/$CREATED_ID/unarchive"
check "4.1 unarchive -> 200" "200" "$HTTP_STATUS"
req DELETE "/projects/$CREATED_ID"
check "4.2 DELETE em ativo -> 409" "409" "$HTTP_STATUS" "body=$HTTP_BODY"
req POST "/projects/$CREATED_ID/archive"
check "4.3 rearquiva -> 200" "200" "$HTTP_STATUS"

section "5. excluir definitivamente (arquivado)"
req DELETE "/projects/$CREATED_ID"
case "$HTTP_STATUS" in 200|204) pass "5.1 DELETE arquivado -> $HTTP_STATUS";; *) fail "5.1 DELETE arquivado" "esperado 200/204, obtido=$HTTP_STATUS body=$HTTP_BODY";; esac
req GET "/projects/$CREATED_ID"
check "5.2 GET /:id após delete -> 404" "404" "$HTTP_STATUS"
req GET "/projects?status=archived"
check "5.3 sumiu de archived" "false" "$(jqr --arg id "$CREATED_ID" 'any(.[]; .id==$id)')"
CREATED_ID=""   # já apagado; evita cleanup redundante

section "Resumo"
printf '%sPASS=%d%s  %sFAIL=%d%s\n' "$g" "$PASS" "$o" "$r" "$FAIL" "$o"
if [ "$FAIL" -gt 0 ]; then printf '%sFalhas:%s %s\n' "$r" "$o" "${FAILED[*]}"; exit 1; fi
echo "${g}Tudo verde contra ${BASE_URL}.${o}"
