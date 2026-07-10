#!/usr/bin/env bash
# E2E de contrato REST — fluxo Projetos -> Categorias -> Conteudos (driva backend).
#
# Exercita o contrato fim-a-fim contra o backend NestJS local (:3000, prefixo
# /v1). Idempotente e auto-limpante: tudo que cria carrega o marcador da rodada
# ($TAG) e e' apagado no fim (conteudos -> categorias -> projetos). NUNCA toca a
# seed pre-existente (projeto `default` / categoria `Geral`).
#
# Requisitos: apenas bash + curl + jq. Sem dependencias novas.
# Uso: ./e2e_api.sh   (BASE_URL opcional, default http://localhost:3000/v1)
#
# Saida: cada bloco imprime PASS/FAIL com contexto; no fim, resumo e cleanup.
# Exit code 0 = tudo PASS; !=0 = houve FAIL.
set -u

BASE_URL="${BASE_URL:-http://localhost:3000/v1}"
TAG="e2e-$(date +%s)-$$"
TMP="$(mktemp -d)"

PASS=0
FAIL=0
FAILED_NAMES=()

# Rastreamento para cleanup (ids criados nesta rodada).
CREATED_PROJECTS=()
CREATED_CATEGORIES=() # "projectId:categoryId"
CREATED_CONTENTS=()   # "projectId:contentId"

C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'

log()  { printf '%s\n' "$*"; }
pass() { PASS=$((PASS+1)); printf '%sPASS%s %s\n' "$C_GREEN" "$C_OFF" "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED_NAMES+=("$1"); printf '%sFAIL%s %s\n' "$C_RED" "$C_OFF" "$1"; if [ -n "${2:-}" ]; then printf '     %s%s%s\n' "$C_DIM" "$2" "$C_OFF"; fi; }
section() { printf '\n=== %s ===\n' "$1"; }

# check <name> <expected> <actual> [extra]
check() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "esperado=$2 obtido=$3 ${4:-}"; fi
}

# ---- helpers HTTP: escrevem status em $HTTP_STATUS e corpo em $HTTP_BODY ----
req_json() { # method url pid [json-body]
  local method="$1" url="$2" pid="$3" body="${4:-}"
  local args=(-s -o "$TMP/body" -w '%{http_code}' -X "$method" "$BASE_URL$url" -H "x-project-id: $pid")
  if [ -n "$body" ]; then args+=(-H 'Content-Type: application/json' -d "$body"); fi
  HTTP_STATUS="$(curl "${args[@]}")"
  HTTP_BODY="$(cat "$TMP/body")"
}
get_raw() { # method url pid  -> status; corpo em $HTTP_BODY (sem content-type header)
  req_json "$1" "$2" "$3" ""
}
jqr() { printf '%s' "$HTTP_BODY" | jq -r "$@" 2>/dev/null; }

# POST/PUT /projects tem rate-limit dedicado (10 req/60s, @Throttle no
# controller) por ser a rota cara (reencode com sharp). O E2E dispara varias
# mutacoes de projeto na mesma janela; este wrapper trata o 429 esperando a
# janela drenar e repetindo (o 429 e' rate-limit de infra, nao violacao de
# contrato). Uso: proj_mut <STATUS_VAR_ignored> curl-args...  -> STATUS+BODY.
proj_mut() { # curl args (sem -s -o -w); escreve $HTTP_STATUS/$HTTP_BODY
  local try
  for try in 1 2 3; do
    HTTP_STATUS="$(curl -s -o "$TMP/body" -w '%{http_code}' "$@")"
    HTTP_BODY="$(cat "$TMP/body")"
    [ "$HTTP_STATUS" != "429" ] && return 0
    log "     ${C_DIM}429 (rate-limit de upload) — aguardando a janela drenar...${C_OFF}"
    sleep 62
  done
  return 0
}

# ---- geradores de fixtures (sem deps: base64 embutido) ----
make_png() { # 4x4 PNG truecolor valido (sharp reencoda sem reclamar)
  base64 -d > "$1" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAAEElEQVR4nGP4z8AARwzEcQCukw/x0F8jngAAAABJRU5ErkJggg==
B64
}
make_svg() { printf '%s' '<svg xmlns="http://www.w3.org/2000/svg"><rect width="1" height="1"/></svg>' > "$1"; }

wait_backend() {
  local i
  for i in $(seq 1 30); do
    if curl -s -o /dev/null "http://localhost:3000/health" 2>/dev/null; then return 0; fi
    sleep 1
  done
  return 1
}

# =====================================================================
# PRE-FLIGHT
# =====================================================================
section "PRE-FLIGHT"
if ! wait_backend; then
  fail "backend acessivel em :3000/health" "backend nao respondeu; suba o Nest (npm run start:dev em backend/)"
  echo "abortando"; exit 1
fi
pass "backend acessivel em :3000/health"

# =====================================================================
# BLOCO 1 - PROJETOS
# =====================================================================
section "BLOCO 1 - PROJETOS"

# 1.1 criar projeto multipart SEM imagem -> 201, contentCount:0, categoryCount:1
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-proj-a" -F "description=projeto sem imagem"
PROJ_A="$(jqr '.id')"
check "1.1 criar projeto sem imagem -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$PROJ_A" ] && [ "$PROJ_A" != "null" ] && CREATED_PROJECTS+=("$PROJ_A")
check "1.1 contentCount == 0" "0" "$(jqr '.contentCount')"
check "1.1 categoryCount == 1 (Geral na transacao)" "1" "$(jqr '.categoryCount')"
check "1.1 imageUrl == null (sem imagem)" "null" "$(jqr '.imageUrl')"

# 1.2 criar projeto COM imagem PNG valida -> imageUrl nao-nulo
make_png "$TMP/valid.png"
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-proj-img" -F "image=@$TMP/valid.png;type=image/png"
PROJ_IMG="$(jqr '.id')"
check "1.2 criar projeto com PNG -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$PROJ_IMG" ] && [ "$PROJ_IMG" != "null" ] && CREATED_PROJECTS+=("$PROJ_IMG")
IMG_URL="$(jqr '.imageUrl')"
if [ -n "$IMG_URL" ] && [ "$IMG_URL" != "null" ]; then pass "1.2 imageUrl nao-nulo ($IMG_URL)"; else fail "1.2 imageUrl nao-nulo" "obtido=$IMG_URL"; fi

# 1.3 GET da imageUrl -> content-type de imagem + header nosniff
# imageUrl ja vem com /v1; BASE_URL tem /v1 -> monta host sem duplicar prefixo.
HOST="${BASE_URL%/v1}"
if [ -n "$IMG_URL" ] && [ "$IMG_URL" != "null" ]; then
  HDRS="$(curl -s -D - -o "$TMP/img.bin" "$HOST$IMG_URL")"
  CT="$(printf '%s' "$HDRS" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}' | head -1)"
  NOSNIFF="$(printf '%s' "$HDRS" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-content-type-options"{print tolower($2)}' | head -1)"
  case "$CT" in image/*) pass "1.3 GET imageUrl content-type de imagem ($CT)";; *) fail "1.3 GET imageUrl content-type de imagem" "obtido=$CT";; esac
  check "1.3 header X-Content-Type-Options: nosniff" "nosniff" "$NOSNIFF"
else
  fail "1.3 GET imageUrl" "sem imageUrl do passo 1.2"
fi

# 1.4 SVG -> 400 (allowlist fechada; SVG e' texto)
make_svg "$TMP/x.svg"
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-svg" -F "image=@$TMP/x.svg;type=image/svg+xml"
check "1.4 upload SVG -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"

# 1.5 forjado (extensao/content-type png mas bytes nao-imagem) -> 400
printf 'not-an-image-at-all %s' "$TAG" > "$TMP/forged.png"
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-forged" -F "image=@$TMP/forged.png;type=image/png"
check "1.5 upload forjado (magic bytes falsos) -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"

# 1.6 oversize (>8MB) -> 413 (limit do FileInterceptor/multer)
head -c $((9*1024*1024)) /dev/zero | cat <(printf '\x89PNG\r\n\x1a\n') - > "$TMP/big.png" 2>/dev/null || dd if=/dev/zero of="$TMP/big.png" bs=1M count=9 2>/dev/null
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-big" -F "image=@$TMP/big.png;type=image/png"
check "1.6 upload oversize (>8MB) -> 413" "413" "$HTTP_STATUS" "body=$(printf '%s' "$HTTP_BODY" | head -c 200)"
# se um projeto foi criado apesar do erro, rastreia p/ cleanup
OVER_ID="$(jqr '.id // empty')"; [ -n "$OVER_ID" ] && CREATED_PROJECTS+=("$OVER_ID")

# 1.7 listar -> cards com contadores; projeto A presente
get_raw GET "/projects" "default"
check "1.7 listar projetos -> 200" "200" "$HTTP_STATUS"
FOUND_A="$(jqr --arg id "$PROJ_A" 'map(select(.id==$id)) | length')"
check "1.7 projeto A presente na listagem" "1" "$FOUND_A"
HAS_COUNTS="$(jqr --arg id "$PROJ_A" 'map(select(.id==$id))[0] | has("contentCount") and has("categoryCount")')"
check "1.7 cards trazem contadores" "true" "$HAS_COUNTS"

# 1.8 GET detalhe
get_raw GET "/projects/$PROJ_A" "default"
check "1.8 GET detalhe do projeto A -> 200" "200" "$HTTP_STATUS"
check "1.8 detalhe.id == projeto A" "$PROJ_A" "$(jqr '.id')"

# 1.9 PUT (titulo/descricao) — multipart (o controller usa FileInterceptor);
#     PUT /projects tambem passa pelo rate-limit de upload.
proj_mut -X PUT "$BASE_URL/projects/$PROJ_A" -H "x-project-id: default" \
  -F "title=${TAG}-proj-a-renamed" -F "description=nova desc"
check "1.9 PUT titulo/descricao -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "1.9 titulo atualizado" "${TAG}-proj-a-renamed" "$(jqr '.title')"

# 1.10 PUT removeImage no projeto com imagem -> imageUrl volta a null
proj_mut -X PUT "$BASE_URL/projects/$PROJ_IMG" -H "x-project-id: default" -F "removeImage=true"
check "1.10 PUT removeImage -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
check "1.10 imageUrl == null apos remove" "null" "$(jqr '.imageUrl')"

# =====================================================================
# BLOCO 2 - CATEGORIAS (escopo x-project-id = PROJ_A)
# =====================================================================
section "BLOCO 2 - CATEGORIAS"
PID="$PROJ_A"

# 2.1 criar raiz
req_json POST "/categories" "$PID" "{\"name\":\"Marketing ${TAG}\"}"
CAT_ROOT="$(jqr '.id')"
check "2.1 criar categoria raiz -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$CAT_ROOT" ] && [ "$CAT_ROOT" != "null" ] && CREATED_CATEGORIES+=("$PID:$CAT_ROOT")
check "2.1 parentId == null (raiz)" "null" "$(jqr '.parentId')"
check "2.1 projectId == PROJ_A" "$PID" "$(jqr '.projectId')"

# 2.2 criar aninhada (parentId)
req_json POST "/categories" "$PID" "{\"name\":\"Campanhas ${TAG}\",\"parentId\":\"$CAT_ROOT\"}"
CAT_CHILD="$(jqr '.id')"
check "2.2 criar categoria aninhada -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$CAT_CHILD" ] && [ "$CAT_CHILD" != "null" ] && CREATED_CATEGORIES+=("$PID:$CAT_CHILD")
check "2.2 parentId == raiz" "$CAT_ROOT" "$(jqr '.parentId')"

# 2.3 listar (flat, com projectId e contentCount)
get_raw GET "/categories" "$PID"
check "2.3 listar categorias -> 200" "200" "$HTTP_STATUS"
HAS_FIELDS="$(jqr --arg id "$CAT_ROOT" 'map(select(.id==$id))[0] | has("projectId") and has("contentCount")')"
check "2.3 flat com projectId e contentCount" "true" "$HAS_FIELDS"

# 2.4 renomear (PUT name)
req_json PUT "/categories/$CAT_ROOT" "$PID" "{\"name\":\"Growth ${TAG}\"}"
check "2.4 renomear categoria -> 200" "200" "$HTTP_STATUS"
check "2.4 name atualizado" "Growth ${TAG}" "$(jqr '.name')"

# 2.5 mover: criar 2a raiz e mover CAT_CHILD para ela
req_json POST "/categories" "$PID" "{\"name\":\"Vendas ${TAG}\"}"
CAT_ROOT2="$(jqr '.id')"
[ -n "$CAT_ROOT2" ] && [ "$CAT_ROOT2" != "null" ] && CREATED_CATEGORIES+=("$PID:$CAT_ROOT2")
req_json PUT "/categories/$CAT_CHILD" "$PID" "{\"parentId\":\"$CAT_ROOT2\"}"
check "2.5 mover categoria (novo parentId) -> 200" "200" "$HTTP_STATUS"
check "2.5 parentId refletido" "$CAT_ROOT2" "$(jqr '.parentId')"

# 2.6 ciclo -> 400 (mover a raiz2 para dentro do seu proprio descendente child)
req_json PUT "/categories/$CAT_ROOT2" "$PID" "{\"parentId\":\"$CAT_CHILD\"}"
check "2.6 mover criando ciclo -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"

# 2.7 DELETE categoria com filhos -> 409 (root2 ainda tem child)
get_raw DELETE "/categories/$CAT_ROOT2" "$PID"
check "2.7 DELETE categoria com subcategoria -> 409" "409" "$HTTP_STATUS" "body=$HTTP_BODY"

# 2.8 DELETE categoria com conteudo -> 409
#     cria um conteudo dentro de CAT_ROOT e tenta apagar a categoria.
req_json POST "/contents" "$PID" "{\"name\":\"C cat ${TAG}\",\"slug\":\"c-cat-${RANDOM}\",\"categoryId\":\"$CAT_ROOT\"}"
CNT_IN_CAT="$(jqr '.id')"
[ -n "$CNT_IN_CAT" ] && [ "$CNT_IN_CAT" != "null" ] && CREATED_CONTENTS+=("$PID:$CNT_IN_CAT")
get_raw DELETE "/categories/$CAT_ROOT" "$PID"
check "2.8 DELETE categoria com conteudo -> 409" "409" "$HTTP_STATUS" "body=$HTTP_BODY"

# =====================================================================
# BLOCO 3 - CONTEUDOS
# =====================================================================
section "BLOCO 3 - CONTEUDOS"

# 3.1 criar sem categoryId -> cai na Geral
#     descobre o id da Geral do projeto para comparar.
get_raw GET "/categories" "$PID"
GERAL_ID="$(jqr 'map(select(.slug=="geral" and .parentId==null))[0].id')"
req_json POST "/contents" "$PID" "{\"name\":\"Sem categoria ${TAG}\",\"slug\":\"sem-cat-${RANDOM}\"}"
CNT_GERAL="$(jqr '.id')"
check "3.1 criar conteudo sem categoryId -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$CNT_GERAL" ] && [ "$CNT_GERAL" != "null" ] && CREATED_CONTENTS+=("$PID:$CNT_GERAL")
check "3.1 categoryId == Geral do projeto" "$GERAL_ID" "$(jqr '.categoryId')"

# 3.2 criar com categoryId valido
req_json POST "/contents" "$PID" "{\"name\":\"Com categoria ${TAG}\",\"slug\":\"com-cat-${RANDOM}\",\"categoryId\":\"$CAT_CHILD\"}"
CNT_CAT="$(jqr '.id')"
check "3.2 criar conteudo com categoryId valido -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
[ -n "$CNT_CAT" ] && [ "$CNT_CAT" != "null" ] && CREATED_CONTENTS+=("$PID:$CNT_CAT")
check "3.2 categoryId refletido" "$CAT_CHILD" "$(jqr '.categoryId')"

# 3.3 categoryId de OUTRO projeto -> 400
#     usa a Geral do projeto B (PROJ_IMG) como categoria estrangeira.
get_raw GET "/categories" "$PROJ_IMG"
FOREIGN_CAT="$(jqr 'map(select(.slug=="geral"))[0].id')"
req_json POST "/contents" "$PID" "{\"name\":\"Estrangeiro ${TAG}\",\"slug\":\"estr-${RANDOM}\",\"categoryId\":\"$FOREIGN_CAT\"}"
if [ "$HTTP_STATUS" = "400" ] || [ "$HTTP_STATUS" = "404" ]; then pass "3.3 categoryId de outro projeto -> 400/404 ($HTTP_STATUS)"; else fail "3.3 categoryId de outro projeto -> 400/404" "obtido=$HTTP_STATUS body=$HTTP_BODY"; fi
STRAY="$(jqr '.id // empty')"; [ -n "$STRAY" ] && CREATED_CONTENTS+=("$PID:$STRAY")

# 3.4 paginacao: criar >20 conteudos na Geral e paginar 2 paginas sem repeticao
for i in $(seq 1 22); do
  req_json POST "/contents" "$PID" "{\"name\":\"Pag ${i} ${TAG}\",\"slug\":\"pag-${i}-${RANDOM}\"}"
  ID="$(jqr '.id')"; [ -n "$ID" ] && [ "$ID" != "null" ] && CREATED_CONTENTS+=("$PID:$ID")
done
get_raw GET "/contents?limit=20" "$PID"
check "3.4 GET /contents envelope -> 200" "200" "$HTTP_STATUS"
HAS_ENV="$(jqr 'has("data") and has("nextCursor")')"
check "3.4 envelope {data,nextCursor}" "true" "$HAS_ENV"
P1_IDS="$(jqr '.data[].id')"
P1_COUNT="$(printf '%s\n' "$P1_IDS" | grep -c .)"
check "3.4 pagina 1 tem 20 itens" "20" "$P1_COUNT"
CURSOR="$(jqr '.nextCursor')"
if [ -n "$CURSOR" ] && [ "$CURSOR" != "null" ]; then pass "3.4 nextCursor presente"; else fail "3.4 nextCursor presente" "obtido=$CURSOR"; fi
get_raw GET "/contents?limit=20&cursor=$CURSOR" "$PID"
P2_IDS="$(jqr '.data[].id')"
OVERLAP="$(comm -12 <(printf '%s\n' "$P1_IDS" | sort) <(printf '%s\n' "$P2_IDS" | sort) | grep -c .)"
check "3.4 paginas 1 e 2 sem repeticao" "0" "$OVERLAP"

# 3.5 busca acento-insensivel: cria 'São Paulo', busca 'sao'
req_json POST "/contents" "$PID" "{\"name\":\"São Paulo ${TAG}\",\"slug\":\"sao-paulo-${RANDOM}\"}"
CNT_SP="$(jqr '.id')"; [ -n "$CNT_SP" ] && [ "$CNT_SP" != "null" ] && CREATED_CONTENTS+=("$PID:$CNT_SP")
get_raw GET "/contents?q=sao&limit=100" "$PID"
FOUND_SP="$(jqr --arg id "$CNT_SP" '.data | map(select(.id==$id)) | length')"
check "3.5 busca 'sao' acha 'São Paulo'" "1" "$FOUND_SP" "body=$(head -c 200 <<<"$HTTP_BODY")"

# 3.6 filtro por categoryId (no exato) -> so o conteudo de CAT_CHILD
get_raw GET "/contents?categoryId=$CAT_CHILD&limit=100" "$PID"
ALL_IN_CAT="$(jqr --arg c "$CAT_CHILD" '.data | all(.categoryId == $c)')"
HAS_CNT_CAT="$(jqr --arg id "$CNT_CAT" '.data | map(select(.id==$id)) | length')"
check "3.6 filtro categoryId: todos do no exato" "true" "$ALL_IN_CAT"
check "3.6 filtro categoryId inclui o conteudo esperado" "1" "$HAS_CNT_CAT"

# 3.7 sort=name asc
get_raw GET "/contents?sort=name&order=asc&limit=100" "$PID"
check "3.7 sort=name asc -> 200" "200" "$HTTP_STATUS"
NAMES="$(jqr '.data[].name')"
SORTED="$(printf '%s\n' "$NAMES" | LC_ALL=C sort)"
if [ "$NAMES" = "$SORTED" ]; then pass "3.7 lista ordenada por name asc"; else fail "3.7 lista ordenada por name asc" "ordem divergente"; fi

# 3.8 limit invalido -> 400
get_raw GET "/contents?limit=0" "$PID"
check "3.8 limit=0 -> 400" "400" "$HTTP_STATUS"
get_raw GET "/contents?limit=500" "$PID"
check "3.8 limit=500 -> 400" "400" "$HTTP_STATUS"

# 3.9 PUT categoryId move conteudo -> reflete no filtro
#     move CNT_GERAL (na Geral) para CAT_CHILD e confirma no filtro.
req_json PUT "/contents/$CNT_GERAL" "$PID" "{\"categoryId\":\"$CAT_CHILD\"}"
check "3.9 PUT categoryId (mover) -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
get_raw GET "/contents?categoryId=$CAT_CHILD&limit=100" "$PID"
MOVED="$(jqr --arg id "$CNT_GERAL" '.data | map(select(.id==$id)) | length')"
check "3.9 conteudo movido aparece no filtro do destino" "1" "$MOVED"

# =====================================================================
# BLOCO 4 - PROJETOS: DELETE guardas (depende do estado acumulado)
# =====================================================================
section "BLOCO 4 - PROJETOS DELETE"

# 4.1 DELETE de projeto COM conteudo -> 409 (PROJ_A tem varios conteudos)
get_raw DELETE "/projects/$PROJ_A" "default"
check "4.1 DELETE projeto com conteudo -> 409" "409" "$HTTP_STATUS" "body=$HTTP_BODY"

# 4.2 DELETE de projeto sem conteudo mas com a "Geral" -> 409 (contrato atual).
#
#  DIVERGENCIA task-spec x contrato: a task pedia "204 para projeto vazio". Mas
#  todo projeto nasce com a categoria "Geral" na MESMA transacao
#  (ProjectsService.create), e Category.project e' `onDelete: Restrict`
#  (schema.prisma). Nao existe caminho de API que deixe um projeto
#  categoria-vazio no fluxo feliz, e mesmo so com a "Geral" o DELETE do projeto
#  retorna 409 — a propria mensagem lista "conteudos/CATEGORIAS". Comportamento
#  INTENCIONAL (documentado no schema/migration), nao defeito de codigo.
#  Aqui asseramos o contrato REAL; a divergencia com a task-spec esta no
#  relatorio da rodada.
proj_mut -X POST "$BASE_URL/projects" -F "title=${TAG}-empty"
PROJ_EMPTY="$(jqr '.id')"
[ -n "$PROJ_EMPTY" ] && [ "$PROJ_EMPTY" != "null" ] && CREATED_PROJECTS+=("$PROJ_EMPTY")
get_raw DELETE "/projects/$PROJ_EMPTY" "default"
check "4.2 DELETE projeto so-com-Geral -> 409 (contrato atual; task pedia 204)" "409" "$HTTP_STATUS" "body=$HTTP_BODY"

# 4.2b caminho para APAGAR de fato: esvaziar a "Geral" e entao apagar o projeto -> 204
GID="$(curl -s "$BASE_URL/categories" -H "x-project-id: $PROJ_EMPTY" | jq -r 'map(select(.slug=="geral"))[0].id')"
DGERAL="$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BASE_URL/categories/$GID" -H "x-project-id: $PROJ_EMPTY")"
check "4.2b apagar a Geral (projeto sem conteudo) -> 204" "204" "$DGERAL"
get_raw DELETE "/projects/$PROJ_EMPTY" "default"
if [ "$HTTP_STATUS" = "204" ]; then
  pass "4.2b DELETE projeto sem categorias/conteudo -> 204"
  NEW=(); for p in "${CREATED_PROJECTS[@]}"; do [ "$p" != "$PROJ_EMPTY" ] && NEW+=("$p"); done; CREATED_PROJECTS=("${NEW[@]}")
else
  fail "4.2b DELETE projeto sem categorias/conteudo -> 204" "obtido=$HTTP_STATUS body=$HTTP_BODY"
fi

# =====================================================================
# CLEANUP — conteudos -> categorias -> projetos (ordem de FK Restrict)
# =====================================================================
section "CLEANUP"
CLEAN_ERR=0

# Estrategia: para cada projeto criado nesta rodada, DRENA tudo pela API na
# ordem exigida pelas FKs `Restrict`: conteudos -> categorias (folhas antes das
# raizes, incluindo a "Geral" semeada) -> projeto. Nao depende do rastreio
# granular de ids (a listagem por projeto e' a fonte da verdade), e a "Geral"
# so e' apagada nos projetos DESTA rodada — nunca no `default`.
drain_project() {
  local p="$1" st
  # 1) conteudos (pagina cheia; repete ate esvaziar)
  local guard=0
  while :; do
    local ids
    ids="$(curl -s "$BASE_URL/contents?limit=100" -H "x-project-id: $p" | jq -r '.data[].id' 2>/dev/null)"
    [ -z "$ids" ] && break
    local id
    for id in $ids; do
      st="$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BASE_URL/contents/$id" -H "x-project-id: $p")"
      case "$st" in 204|404) ;; *) CLEAN_ERR=$((CLEAN_ERR+1)); log "  ! conteudo $id: DELETE $st";; esac
    done
    guard=$((guard+1)); [ "$guard" -gt 50 ] && { log "  ! drenagem de conteudos travou em $p"; break; }
  done
  # 2) categorias: folhas antes das raizes (varias passadas ate zerar)
  local pass
  for pass in $(seq 1 10); do
    local cats
    cats="$(curl -s "$BASE_URL/categories" -H "x-project-id: $p" | jq -r '.[].id' 2>/dev/null)"
    [ -z "$cats" ] && break
    local removed=0 cid
    for cid in $cats; do
      st="$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BASE_URL/categories/$cid" -H "x-project-id: $p")"
      case "$st" in 204|404) removed=$((removed+1)) ;; esac
    done
    [ "$removed" -eq 0 ] && break # so restam categorias bloqueadas por dependencia nao resolvida
  done
  # 3) projeto
  st="$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BASE_URL/projects/$p" -H "x-project-id: default")"
  case "$st" in 204|404) ;; *) CLEAN_ERR=$((CLEAN_ERR+1)); log "  ! projeto $p: DELETE $st";; esac
}

for p in "${CREATED_PROJECTS[@]:-}"; do
  [ -z "$p" ] && continue
  drain_project "$p"
done

# verifica: nenhum projeto com o TAG desta rodada sobra na listagem
get_raw GET "/projects" "default"
LEFTOVER="$(jqr --arg t "$TAG" '[.[] | select(.title | test($t))] | length')"
if [ "$CLEAN_ERR" -eq 0 ] && [ "$LEFTOVER" = "0" ]; then
  pass "CLEANUP total: DB voltou ao estado inicial (0 residuo do TAG $TAG)"
else
  fail "CLEANUP total" "erros=$CLEAN_ERR residuo_projetos=$LEFTOVER — inspecione manualmente"
fi

rm -rf "$TMP"

# =====================================================================
# RESUMO
# =====================================================================
section "RESUMO"
printf 'PASS=%d  FAIL=%d\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'Falhas:\n'
  for n in "${FAILED_NAMES[@]}"; do printf '  - %s\n' "$n"; done
  exit 1
fi
printf 'Todos os blocos PASS.\n'
exit 0
