#!/usr/bin/env bash
# E2E de contrato — item 24 (publicação e versionamento) CONTRA A HOMOLOGAÇÃO.
#
# Cobre o critério de aceite do §4/P1 do plan.md inteiro, por API:
# criar → público 404 → publish v1 → republicar sem mudar (idempotente, D3) →
# novo spec → v2 → lista desc + paginação por cursor → API pública serve o
# PUBLICADO e não o rascunho (ETag por publishedAt) → restore traz para o
# rascunho sem mexer no ar (D4) → cross-tenant 404 → bordas de validação →
# unpublish → DELETE cascade nas versões → exclusão de projeto (item 9e).
#
# Idempotente e auto-limpante. Rastro criado e removido:
#   · 1 conteúdo com slug $SLUG no projeto $PROJECT (purgado no início E no fim)
#   · 1 projeto descartável "E2E 24 cross-tenant …" (arquivado e excluído no fim)
#   · $TMP (mktemp -d)
# NUNCA toca a seed `default` além de criar/apagar o conteúdo de teste.
#
# Requisitos: bash + curl + jq. Uso:
#   docs/24-publicacao-versionamento/e2e_hml.sh                       # hml (default)
#   BASE_URL=http://localhost:3000/v1 docs/.../e2e_hml.sh             # smoke local
#
# Saída: PASS/FAIL por checagem; exit 0 = tudo PASS.
set -u

BASE_URL="${BASE_URL:-https://api-hml.driva.duckdns.org/v1}"
PROJECT="${PROJECT:-default}"
SLUG="${SLUG:-e2e-24-publicacao}"
NAME="E2E 24 publicação"
TMP="$(mktemp -d)"
PASS=0; FAIL=0; FAILED=()
CONTENT_ID=""
OTHER_PROJECT=""
OTHER_CONTENT=""
KEY=""
OTHER_KEY=""

g=$'\033[32m'; r=$'\033[31m'; d=$'\033[2m'; o=$'\033[0m'
pass() { PASS=$((PASS+1)); printf '%sPASS%s %s\n' "$g" "$o" "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED+=("$1"); printf '%sFAIL%s %s\n' "$r" "$o" "$1"; [ -n "${2:-}" ] && printf '     %s%s%s\n' "$d" "$2" "$o"; return 0; }
check() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "esperado=$2 obtido=$3 ${4:-}"; fi }
section() { printf '\n=== %s ===\n' "$1"; }

PH=(-H "x-project-id: $PROJECT")
JH=(-H 'content-type: application/json')

req() { # method path [curl-args...]
  local method="$1" path="$2"; shift 2
  HTTP_STATUS="$(curl -s -o "$TMP/body" -D "$TMP/head" -w '%{http_code}' -X "$method" "$BASE_URL$path" "$@")"
  HTTP_BODY="$(cat "$TMP/body")"
}
jqr() { printf '%s' "$HTTP_BODY" | jq -r "$@" 2>/dev/null; }
etag() { grep -i '^etag:' "$TMP/head" | tail -1 | tr -d '\r' | cut -d' ' -f2-; }

# O rascunho é sempre um spec válido de uma folha `text`, com o marcador no
# `props.data` — é por ele que se prova QUAL spec a API pública está servindo.
spec_of() { # contentId marker
  jq -nc --arg id "$1" --arg name "$NAME" --arg slug "$SLUG" --arg m "$2" \
    '{spec:{specVersion:1,kind:"content",id:$id,name:$name,slug:$slug,
            root:{id:"nd_root",type:"text",props:{data:$m}}}}'
}

purge_slug() { # projectHeader
  local list
  list="$(curl -s -H "x-project-id: $1" "$BASE_URL/contents?q=$SLUG&limit=100" \
    | jq -r --arg s "$SLUG" '(.data // [])[] | select(.slug==$s) | .id' 2>/dev/null)"
  for id in $list; do
    curl -s -o /dev/null -X DELETE -H "x-project-id: $1" "$BASE_URL/contents/$id"
  done
}

cleanup() {
  [ -n "$CONTENT_ID" ] && curl -s -o /dev/null -X DELETE "${PH[@]}" "$BASE_URL/contents/$CONTENT_ID"
  if [ -n "$OTHER_PROJECT" ]; then
    [ -n "$OTHER_CONTENT" ] && curl -s -o /dev/null -X DELETE \
      -H "x-project-id: $OTHER_PROJECT" "$BASE_URL/contents/$OTHER_CONTENT"
    curl -s -o /dev/null -X POST "$BASE_URL/projects/$OTHER_PROJECT/archive"
    curl -s -o /dev/null -X DELETE "$BASE_URL/projects/$OTHER_PROJECT"
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

command -v jq >/dev/null || { echo "${r}jq ausente${o}"; exit 1; }
echo "Alvo: ${BASE_URL}   projeto: ${PROJECT}   slug: ${SLUG}"
purge_slug "$PROJECT"

# ---------------------------------------------------------------------------
section "0. ambiente no ar"
req GET "/contents?limit=1" "${PH[@]}"
check "0.1 GET /contents -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"

req GET "/projects"
check "0.2 GET /projects -> 200" "200" "$HTTP_STATUS"
KEY="$(jqr --arg p "$PROJECT" '.[] | select(.id==$p) | .publishableKey')"
if [ -n "$KEY" ] && [ "$KEY" != "null" ]; then
  pass "0.3 chave publicável do projeto ${PROJECT} (${KEY:0:10}…)"
else
  fail "0.3 chave publicável do projeto ${PROJECT}" "projeto não encontrado em GET /projects"
  echo "${r}Sem chave publicável não dá para checar a API pública — abortando.${o}"; exit 1
fi

req POST "/projects" -F "title=E2E 24 cross-tenant $(date +%s)" -F "description=projeto descartável do e2e do item 24"
check "0.4 projeto descartável criado -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
OTHER_PROJECT="$(jqr '.id')"
OTHER_KEY="$(jqr '.publishableKey')"
[ -n "$OTHER_PROJECT" ] && [ "$OTHER_PROJECT" != "null" ] \
  && pass "0.5 id do projeto descartável ($OTHER_PROJECT)" \
  || { fail "0.5 id do projeto descartável" "body=$HTTP_BODY"; exit 1; }

# Categoria explícita em vez de confiar no fallback "Geral" do servidor: em
# uso real a categoria default de um projeto pode ter sido renomeada (é o
# caso do projeto "default" em hml), e criar sem categoryId quebraria por um
# motivo alheio a este item.
req GET "/categories" "${PH[@]}"
CATEGORY_ID="$(jqr '.[0].id')"
[ -n "$CATEGORY_ID" ] && [ "$CATEGORY_ID" != "null" ] \
  && pass "0.6 categoria do projeto $PROJECT ($CATEGORY_ID)" \
  || { fail "0.6 categoria do projeto $PROJECT" "projeto sem nenhuma categoria — body=$HTTP_BODY"; exit 1; }

# ---------------------------------------------------------------------------
section "1. criar conteúdo — nasce nunca publicado (D2)"
req POST "/contents" "${PH[@]}" "${JH[@]}" \
  -d "$(jq -nc --arg n "$NAME" --arg s "$SLUG" --arg c "$CATEGORY_ID" '{name:$n,slug:$s,categoryId:$c}')"
check "1.1 POST /contents -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
CONTENT_ID="$(jqr '.id')"
[ -n "$CONTENT_ID" ] && [ "$CONTENT_ID" != "null" ] \
  && pass "1.2 id retornado ($CONTENT_ID)" || { fail "1.2 id retornado" "body=$HTTP_BODY"; exit 1; }
check "1.3 summary.publishedAt null" "null" "$(jqr '.publishedAt')"
check "1.4 summary.hasUnpublishedChanges true" "true" "$(jqr '.hasUnpublishedChanges')"

req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "1.5 GET :id -> 200" "200" "$HTTP_STATUS"
check "1.6 GET :id publishedVersion null" "null" "$(jqr '.publishedVersion')"
check "1.7 GET :id hasUnpublishedChanges true" "true" "$(jqr '.hasUnpublishedChanges')"
check "1.8 GET :id ainda devolve a chave 'spec' (D6, é o rascunho)" "true" "$(jqr 'has("spec")')"

req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "1.9 conteúdo novo não tem versão" "0" "$(jqr '.data | length')"

# ---------------------------------------------------------------------------
section "2. API pública antes de publicar — 404 (débito VR-13-01 fechado)"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "2.1 GET /public/contents/:slug (nunca publicado) -> 404" "404" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/public/contents" -H "x-driva-key: $KEY"
check "2.2 não aparece em GET /public/contents" "false" \
  "$(jqr --arg s "$SLUG" 'any((.data // [])[]; .slug==$s)')"

# ---------------------------------------------------------------------------
section "3. publicar — versão 1"
req PUT "/contents/$CONTENT_ID" "${PH[@]}" "${JH[@]}" -d "$(spec_of "$CONTENT_ID" 'VERSAO-1')"
check "3.1 PUT do spec -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
# D7 deriva hasUnpublishedChanges de timestamps com resolução de ms: o publish
# tem que cair num milissegundo posterior ao PUT, senão a mudança "não existe".
sleep 0.1

req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{"note":"primeira publicação do e2e"}'
check "3.2 POST :id/publish -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "3.3 publishedVersion.version == 1" "1" "$(jqr '.publishedVersion.version')"
check "3.4 hasUnpublishedChanges false" "false" "$(jqr '.hasUnpublishedChanges')"

req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "3.5 GET :id publishedVersion.version == 1" "1" "$(jqr '.publishedVersion.version')"
check "3.6 GET :id hasUnpublishedChanges false" "false" "$(jqr '.hasUnpublishedChanges')"

req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "3.7 GET :id/versions traz 1 item" "1" "$(jqr '.data | length')"
check "3.8 a nota foi guardada na versão" "primeira publicação do e2e" "$(jqr '.data[0].note')"

req GET "/contents?q=$SLUG&limit=100" "${PH[@]}"
check "3.9 summary da lista tem publishedAt preenchido" "false" \
  "$(jqr --arg i "$CONTENT_ID" '[(.data // [])[] | select(.id==$i)][0].publishedAt == null')"
check "3.10 summary da lista tem hasUnpublishedChanges false" "false" \
  "$(jqr --arg i "$CONTENT_ID" '[(.data // [])[] | select(.id==$i)][0].hasUnpublishedChanges')"

# ---------------------------------------------------------------------------
section "4. publicar de novo sem mudar nada — idempotente (D3)"
req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{}'
check "4.1 publish repetido -> 200 (não 409)" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "4.2 continua na versão 1" "1" "$(jqr '.publishedVersion.version')"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "4.3 nenhuma versão duplicada foi criada" "1" "$(jqr '.data | length')"

# ---------------------------------------------------------------------------
section "5. novo spec — versão 2, mais nova primeiro"
req PUT "/contents/$CONTENT_ID" "${PH[@]}" "${JH[@]}" -d "$(spec_of "$CONTENT_ID" 'VERSAO-2')"
check "5.1 PUT do novo spec -> 200" "200" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "5.2 mudar o rascunho reacende hasUnpublishedChanges" "true" "$(jqr '.hasUnpublishedChanges')"
check "5.3 o que está no ar continua a v1" "1" "$(jqr '.publishedVersion.version')"
sleep 0.1

req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{"note":"segunda"}'
check "5.4 publish -> versão 2" "2" "$(jqr '.publishedVersion.version')"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "5.5 GET :id/versions traz 2 itens" "2" "$(jqr '.data | length')"
check "5.6 mais nova primeiro (data[0] == v2)" "2" "$(jqr '.data[0].version')"
check "5.7 data[1] == v1" "1" "$(jqr '.data[1].version')"
check "5.8 a lista de versões NÃO carrega o spec (peso)" "false" "$(jqr '.data[0] | has("spec")')"

req GET "/contents/$CONTENT_ID/versions/1" "${PH[@]}"
check "5.9 GET :id/versions/1 devolve o spec da v1" "VERSAO-1" "$(jqr '.spec.root.props.data')"
req GET "/contents/$CONTENT_ID/versions/2" "${PH[@]}"
check "5.10 GET :id/versions/2 devolve o spec da v2" "VERSAO-2" "$(jqr '.spec.root.props.data')"

# ---------------------------------------------------------------------------
section "6. API pública serve o PUBLICADO, nunca o rascunho"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "6.1 GET /public/contents/:slug -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "6.2 serve o spec da v2" "VERSAO-2" "$(jqr '.spec.root.props.data')"
ETAG_ANTES="$(etag)"
[ -n "$ETAG_ANTES" ] && pass "6.3 ETag presente ($ETAG_ANTES)" || fail "6.3 ETag presente" "sem header ETag"

req GET "/public/contents" -H "x-driva-key: $KEY"
check "6.4 aparece em GET /public/contents" "true" \
  "$(jqr --arg s "$SLUG" 'any((.data // [])[]; .slug==$s)')"

req PUT "/contents/$CONTENT_ID" "${PH[@]}" "${JH[@]}" -d "$(spec_of "$CONTENT_ID" 'RASCUNHO-NAO-PUBLICADO')"
check "6.5 PUT de um rascunho novo (sem publicar) -> 200" "200" "$HTTP_STATUS"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "6.6 o público ignora o rascunho e continua na v2" "VERSAO-2" "$(jqr '.spec.root.props.data')"
check "6.7 o ETag não muda com autosave do rascunho (vem de publishedAt)" "$ETAG_ANTES" "$(etag)"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY" -H "if-none-match: $ETAG_ANTES"
check "6.8 If-None-Match com o ETag corrente -> 304" "304" "$HTTP_STATUS"

# ---------------------------------------------------------------------------
section "7. restaurar a v1 — vai para o rascunho, o ar não muda (D4)"
req POST "/contents/$CONTENT_ID/versions/1/restore" "${PH[@]}"
check "7.1 restore -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "7.2 o rascunho virou o spec da v1" "VERSAO-1" "$(jqr '.spec.root.props.data')"
check "7.3 o que está no ar continua a v2" "2" "$(jqr '.publishedVersion.version')"
check "7.4 hasUnpublishedChanges reacendeu" "true" "$(jqr '.hasUnpublishedChanges')"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "7.5 restaurar não cria versão nova" "2" "$(jqr '.data | length')"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "7.6 o público continua servindo a v2" "VERSAO-2" "$(jqr '.spec.root.props.data')"

# ---------------------------------------------------------------------------
section "8. republicar depois do restore — v3 e paginação por cursor"
sleep 0.1
req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{"note":"rollback da v1"}'
check "8.1 publish depois do restore -> versão 3" "3" "$(jqr '.publishedVersion.version')"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "8.2 o público passa a servir o conteúdo da v1 (agora publicado como v3)" "VERSAO-1" "$(jqr '.spec.root.props.data')"

req GET "/contents/$CONTENT_ID/versions?limit=2" "${PH[@]}"
check "8.3 primeira página traz 2 itens" "2" "$(jqr '.data | length')"
check "8.4 primeira página começa na v3" "3" "$(jqr '.data[0].version')"
CURSOR="$(jqr '.nextCursor')"
[ -n "$CURSOR" ] && [ "$CURSOR" != "null" ] && pass "8.5 nextCursor devolvido" || fail "8.5 nextCursor devolvido" "nextCursor=$CURSOR"
req GET "/contents/$CONTENT_ID/versions?limit=2&cursor=$CURSOR" "${PH[@]}"
check "8.6 segunda página traz a v1" "1" "$(jqr '.data[0].version')"
check "8.7 segunda página fecha a lista" "null" "$(jqr '.nextCursor')"
check "8.8 sem repetição entre as páginas" "1" "$(jqr '.data | length')"

# ---------------------------------------------------------------------------
section "9. cross-tenant — 404 em tudo, nunca 403 (não revela existência)"
OH=(-H "x-project-id: $OTHER_PROJECT")
req GET "/contents/$CONTENT_ID" "${OH[@]}"
check "9.1 GET :id de outro projeto -> 404" "404" "$HTTP_STATUS"
req POST "/contents/$CONTENT_ID/publish" "${OH[@]}" "${JH[@]}" -d '{}'
check "9.2 publish de outro projeto -> 404" "404" "$HTTP_STATUS" "body=$HTTP_BODY"
req POST "/contents/$CONTENT_ID/unpublish" "${OH[@]}"
check "9.3 unpublish de outro projeto -> 404" "404" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions" "${OH[@]}"
check "9.4 listar versões de outro projeto -> 404" "404" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions/1" "${OH[@]}"
check "9.5 ler versão de outro projeto -> 404" "404" "$HTTP_STATUS"
req POST "/contents/$CONTENT_ID/versions/1/restore" "${OH[@]}"
check "9.6 restaurar de outro projeto -> 404" "404" "$HTTP_STATUS"
req DELETE "/contents/$CONTENT_ID" "${OH[@]}"
check "9.7 DELETE de outro projeto -> 404" "404" "$HTTP_STATUS"
req GET "/public/contents/$SLUG" -H "x-driva-key: $OTHER_KEY"
check "9.8 chave publicável de outro projeto -> 404" "404" "$HTTP_STATUS"

req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "9.9 nada disso alterou o conteúdo (continua no ar na v3)" "3" "$(jqr '.publishedVersion.version')"

# ---------------------------------------------------------------------------
section "10. bordas de validação"
req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" \
  -d "$(jq -nc '{note:("x"*201)}')"
check "10.1 note com 201 chars -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"
req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{"spec":{"specVersion":1}}'
check "10.2 campo fora do DTO no publish -> 400 (o spec nunca vem do cliente)" "400" "$HTTP_STATUS" "body=$HTTP_BODY"
req POST "/contents/nao-existe-$$/publish" "${PH[@]}" "${JH[@]}" -d '{}'
check "10.3 publish de conteúdo inexistente -> 404" "404" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions/99" "${PH[@]}"
check "10.4 versão inexistente -> 404" "404" "$HTTP_STATUS"
req POST "/contents/$CONTENT_ID/versions/99/restore" "${PH[@]}"
check "10.5 restaurar versão inexistente -> 404" "404" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions/abc" "${PH[@]}"
check "10.6 versão não-numérica -> 400 (ParseIntPipe)" "400" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions?limit=0" "${PH[@]}"
check "10.7 limit fora da faixa -> 400" "400" "$HTTP_STATUS"
req GET "/public/contents/$SLUG"
check "10.8 API pública sem chave -> 404" "404" "$HTTP_STATUS"
req GET "/public/contents/$SLUG" -H "x-driva-key: pk_inexistente"
check "10.9 API pública com chave inválida -> 404" "404" "$HTTP_STATUS"

req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "10.10 nenhuma borda criou versão" "3" "$(jqr '.data | length')"

# ---------------------------------------------------------------------------
section "11. despublicar — sai do ar sem apagar histórico"
req POST "/contents/$CONTENT_ID/unpublish" "${PH[@]}"
check "11.1 unpublish -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "11.2 publishedVersion null na resposta" "null" "$(jqr '.publishedVersion')"
req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "11.3 GET :id publishedVersion null" "null" "$(jqr '.publishedVersion')"
check "11.4 GET :id hasUnpublishedChanges true" "true" "$(jqr '.hasUnpublishedChanges')"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "11.5 as 3 versões continuam guardadas" "3" "$(jqr '.data | length')"
req GET "/public/contents/$SLUG" -H "x-driva-key: $KEY"
check "11.6 API pública volta a 404" "404" "$HTTP_STATUS"
req GET "/public/contents" -H "x-driva-key: $KEY"
check "11.7 some de GET /public/contents" "false" \
  "$(jqr --arg s "$SLUG" 'any((.data // [])[]; .slug==$s)')"
req GET "/contents?q=$SLUG&limit=100" "${PH[@]}"
check "11.8 summary volta a publishedAt null" "true" \
  "$(jqr --arg i "$CONTENT_ID" '[(.data // [])[] | select(.id==$i)][0].publishedAt == null')"

sleep 0.1
req POST "/contents/$CONTENT_ID/publish" "${PH[@]}" "${JH[@]}" -d '{}'
check "11.9 republicar depois de despublicar continua a numeração (v4)" "4" "$(jqr '.publishedVersion.version')"

# ---------------------------------------------------------------------------
section "12. DELETE do conteúdo — cascade nas versões"
req DELETE "/contents/$CONTENT_ID" "${PH[@]}"
check "12.1 DELETE do conteúdo com 4 versões -> 204 (cascade, não FK violation)" "204" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CONTENT_ID" "${PH[@]}"
check "12.2 GET :id depois do delete -> 404" "404" "$HTTP_STATUS"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "12.3 GET :id/versions depois do delete -> 404" "404" "$HTTP_STATUS"
req POST "/contents" "${PH[@]}" "${JH[@]}" \
  -d "$(jq -nc --arg n "$NAME" --arg s "$SLUG" --arg c "$CATEGORY_ID" '{name:$n,slug:$s,categoryId:$c}')"
check "12.4 recriar com o mesmo slug -> 201 (nada ficou preso)" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
CONTENT_ID="$(jqr '.id')"
req GET "/contents/$CONTENT_ID/versions" "${PH[@]}"
check "12.5 o conteúdo recriado nasce sem versões" "0" "$(jqr '.data | length')"
req DELETE "/contents/$CONTENT_ID" "${PH[@]}"
check "12.6 DELETE do recriado -> 204" "204" "$HTTP_STATUS"
CONTENT_ID=""

# ---------------------------------------------------------------------------
section "13. exclusão de projeto com conteúdo publicado (regressão do item 9e)"
req POST "/contents" -H "x-project-id: $OTHER_PROJECT" "${JH[@]}" \
  -d "$(jq -nc --arg n "$NAME" --arg s "$SLUG" '{name:$n,slug:$s}')"
check "13.1 conteúdo no projeto descartável -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
OTHER_CONTENT="$(jqr '.id')"
req PUT "/contents/$OTHER_CONTENT" -H "x-project-id: $OTHER_PROJECT" "${JH[@]}" \
  -d "$(spec_of "$OTHER_CONTENT" 'PROJETO-DESCARTAVEL')"
check "13.2 PUT do spec -> 200" "200" "$HTTP_STATUS"
sleep 0.1
req POST "/contents/$OTHER_CONTENT/publish" -H "x-project-id: $OTHER_PROJECT" "${JH[@]}" -d '{}'
check "13.3 publicado no projeto descartável" "1" "$(jqr '.publishedVersion.version')"

req DELETE "/projects/$OTHER_PROJECT"
check "13.4 DELETE de projeto ativo -> 409" "409" "$HTTP_STATUS"
req POST "/projects/$OTHER_PROJECT/archive"
check "13.5 arquivar -> 200" "200" "$HTTP_STATUS"
req DELETE "/projects/$OTHER_PROJECT"
case "$HTTP_STATUS" in
  200|204) pass "13.6 excluir projeto com conteúdo PUBLICADO -> $HTTP_STATUS (as versões cascatearam)";;
  *) fail "13.6 excluir projeto com conteúdo publicado" "esperado 200/204, obtido=$HTTP_STATUS body=$HTTP_BODY";;
esac
req GET "/projects/$OTHER_PROJECT"
check "13.7 projeto sumiu" "404" "$HTTP_STATUS"
OTHER_PROJECT=""; OTHER_CONTENT=""

# ---------------------------------------------------------------------------
section "Resumo"
printf '%sPASS=%d%s  %sFAIL=%d%s\n' "$g" "$PASS" "$o" "$r" "$FAIL" "$o"
if [ "$FAIL" -gt 0 ]; then
  printf '%sFalhas:%s\n' "$r" "$o"
  for f in "${FAILED[@]}"; do printf '  · %s\n' "$f"; done
  exit 1
fi
echo "${g}Tudo verde contra ${BASE_URL}.${o}"
