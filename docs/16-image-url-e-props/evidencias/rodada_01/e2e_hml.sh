#!/usr/bin/env bash
# E2E de contrato — item 39 (URL da imagem e props) CONTRA A HOMOLOGAÇÃO.
#
# O que este script prova, e a suíte `e2e` do Nest NÃO prova:
#
#   A matriz de segurança da §11.4 do plan.md (27–44) já roda no CI, contra um
#   servidor efêmero. Ela atesta o CÓDIGO do proxy. O que ela não pode atestar é
#   o **ambiente**: se o proxy está no ar em hml, se o `CORS_ORIGINS` do Coolify
#   deixa a origem do editor entrar, e se as três URLs da matriz §2 (A/B/C) se
#   comportam hoje como o plano descreve. Isso é o que se mede aqui — a linha 44
#   do DoD diz, com todas as letras, que a suíte verde "não prova que a URL do
#   relato carrega no Chrome".
#
#   Em particular: o caso B só é caso B enquanto o host NÃO servir ACAO. O
#   passo 3.1 confere isso antes de tudo; se o Google passar a servir ACAO, o
#   script FALHA de propósito — um caso B que virou A invalida o teste inteiro
#   (§10 do plan.md).
#
# Complementa o e2e_shots.sh, que captura os quatro estados na TELA do hml.
#
# Idempotente e auto-limpante: purga qualquer rastro do slug $SLUG no começo e no
# fim. NUNCA toca conteúdo que não seja o dele. Rastro removível: um conteúdo de
# teste no projeto `default` do hml (+ uma categoria, só se o projeto não tiver
# nenhuma) e um diretório temporário. Zero mudança de código-fonte.
#
# Requisitos: bash + curl + jq (+ git/grep para as cancelas estáticas). Uso:
#   docs/16-image-url-e-props/e2e_hml.sh
#   API_BASE=http://localhost:3000/v1 docs/16-image-url-e-props/e2e_hml.sh
#
# Saída: PASS/FAIL por checagem; exit 0 = tudo PASS.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_BASE="${API_BASE:-https://api-hml.driva.duckdns.org/v1}"
WEB_BASE="${WEB_BASE:-https://hml.driva.duckdns.org}"
PROJECT="${PROJECT:-default}"
SLUG="${SLUG:-e2e-39-contrato}"
NAME="E2E 39 contrato"
TMP="$(mktemp -d)"
PASS=0; FAIL=0; FAILED=()
CREATED_ID=""
CREATED_CATEGORY_ID=""

URL_A="${URL_A:-https://picsum.photos/300/200}"
URL_B="${URL_B:-https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png}"
URL_C="${URL_C:-https://exemplo.invalido/x.png}"

g=$'\033[32m'; r=$'\033[31m'; y=$'\033[33m'; d=$'\033[2m'; o=$'\033[0m'
pass() { PASS=$((PASS+1)); printf '%sPASS%s %s\n' "$g" "$o" "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED+=("$1"); printf '%sFAIL%s %s\n' "$r" "$o" "$1"; [ -n "${2:-}" ] && printf '     %s%s%s\n' "$d" "$2" "$o"; }
check() { [ "$2" = "$3" ] && pass "$1" || fail "$1" "esperado=$2 obtido=$3 ${4:-}"; }
contains() { case "$3" in *"$2"*) pass "$1";; *) fail "$1" "esperado conter=$2 obtido=$3";; esac; }
section() { printf '\n=== %s ===\n' "$1"; }

urlenc() { jq -rn --arg v "$1" '$v|@uri'; }
proxy_url() { printf '%s/media/proxy?url=%s' "$API_BASE" "$(urlenc "$1")"; }

# Guarda os headers em $TMP/head e o corpo em $TMP/body; devolve o status.
fetch() { # url [curl-args...]
  local url="$1"; shift
  HTTP_STATUS="$(curl -s -o "$TMP/body" -D "$TMP/head" -w '%{http_code}' "$url" "$@")"
  # Corpo de imagem é binário: sem o `tr` o bash avisa "byte nulo ignorado" a
  # cada substituição de comando.
  HTTP_BODY="$(tr -d '\0' < "$TMP/body")"
}
header() { grep -i "^$1:" "$TMP/head" | tail -1 | cut -d' ' -f2- | tr -d '\r'; }

req() { # method path [curl-args...]
  local method="$1" path="$2"; shift 2
  HTTP_STATUS="$(curl -s -o "$TMP/body" -w '%{http_code}' -X "$method" "$API_BASE$path" \
    -H "x-project-id: $PROJECT" "$@")"
  HTTP_BODY="$(cat "$TMP/body")"
}
jqr() { printf '%s' "$HTTP_BODY" | jq -r "$@" 2>/dev/null; }

purge() {
  curl -s -H "x-project-id: $PROJECT" "$API_BASE/contents?q=E2E%2039&limit=100" \
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

resolve_category() {
  CATEGORY_ID="$(curl -s -H "x-project-id: $PROJECT" "$API_BASE/categories" | jq -r '.[0].id // empty')"
  if [ -z "$CATEGORY_ID" ]; then
    CATEGORY_ID="$(curl -s -X POST "$API_BASE/categories" -H "x-project-id: $PROJECT" \
      -H 'content-type: application/json' -d '{"name":"E2E 39"}' | jq -r '.id // empty')"
    CREATED_CATEGORY_ID="$CATEGORY_ID"
  fi
}

# spec <root-json> — o mesmo envelope que ContentSpec.toJson() emite
spec() {
  jq -nc --arg id "$CREATED_ID" --arg name "$NAME" --arg slug "$SLUG" --argjson root "$1" \
    '{specVersion:1, kind:"content", id:$id, name:$name, slug:$slug, root:$root}'
}
image_node() { # props-json
  jq -nc --argjson props "$1" '{id:"nd_img", type:"image", props:$props}'
}

echo "Alvo: ${API_BASE}   editor: ${WEB_BASE}   projeto: ${PROJECT}   slug: ${SLUG}"
purge

section "0. cancelas estáticas do DoD (§11.1 do plan.md)"
if [ -d "$ROOT/.git" ]; then
  cores() { grep -rn "Color(0x" "$ROOT/packages/sdui_flutter/lib" 2>/dev/null | grep -v "lib/src/theme/"; }
  check "0.1 (DoD 5) nenhum Color(0x…) fora de sdui_flutter/lib/src/theme/" "0" "$(cores | wc -l | tr -d ' ')" \
    "$(cores | head -3 | tr '\n' ' ')"
  lb() { grep -rn "loadingBuilder" "$ROOT/packages/sdui_flutter/lib" 2>/dev/null; }
  check "0.2 (DoD 5b) loadingBuilder não é usado — o estado sai do frameBuilder (D12)" "0" "$(lb | wc -l | tr -d ' ')" \
    "$(lb | head -3 | tr '\n' ' ')"
  sd() { grep -rn "showDiagnostics" "$ROOT/apps/driva_demo_app" 2>/dev/null; }
  check "0.3 (DoD 5c) showDiagnostics não aparece no app cliente (D13)" "0" "$(sd | wc -l | tr -d ' ')"
  grep -q "this.showDiagnostics = false" "$ROOT/packages/sdui_flutter/lib/src/sdui_view.dart" \
    && pass "0.4 (DoD 5c) showDiagnostics nasce false no SduiView" \
    || fail "0.4 (DoD 5c) showDiagnostics nasce false no SduiView" "$(grep -n showDiagnostics "$ROOT/packages/sdui_flutter/lib/src/sdui_view.dart" | tr '\n' ' ')"
  if [ -x "$ROOT/scripts/gates_guard.sh" ] || [ -f "$ROOT/scripts/gates_guard.sh" ]; then
    if bash "$ROOT/scripts/gates_guard.sh" >"$TMP/gates" 2>&1; then pass "0.5 (DoD 5d) scripts/gates_guard.sh verde"
    else fail "0.5 (DoD 5d) scripts/gates_guard.sh verde" "$(tail -5 "$TMP/gates" | tr '\n' ' ')"; fi
  fi
  # D11: o proxy é chrome do EDITOR. Se o builder do renderer soubesse a URL do
  # proxy, todo app cliente publicado rotearia imagem pelo nosso backend.
  mp() { grep -rn "media/proxy" "$ROOT/packages" 2>/dev/null; }
  check "0.6 (D11) a URL do proxy não existe dentro de packages/ — só o editor a monta" "0" "$(mp | wc -l | tr -d ' ')" \
    "$(mp | head -3 | tr '\n' ' ')"
  # O que a DoD 6 proíbe é o editor conhecer o tipo: os campos novos da F4 têm
  # de sair do catálogo. Um mapa de ícone por tipo (`palette_icons.dart`) não é
  # isso — o que reprova é um condicional sobre o tipo do nó.
  ife() { grep -rnE "== *'image'|== *\"image\"|'image' *==" "$ROOT/apps/driva_editor/lib" 2>/dev/null; }
  check "0.7 (DoD 6) nenhum condicional sobre o tipo 'image' no editor — os campos vêm do catálogo" "0" "$(ife | wc -l | tr -d ' ')" \
    "$(ife | head -3 | tr '\n' ' ')"
else
  echo "${d}(fora de um checkout — cancelas estáticas puladas)${o}"
fi

section "1. hml no ar (o ambiente da rodada)"
req GET "/contents?limit=1"
check "1.1 GET /contents -> 200" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
fetch "$WEB_BASE/"
check "1.2 editor web servido em $WEB_BASE" "200" "$HTTP_STATUS"
fetch "$WEB_BASE/main.dart.js"
# O bundle publicado tem de conter os três estados e a URL do proxy: sem isso a
# rodada estaria testando um artefato anterior às fases F1–F4.
for s in "media/proxy" "Imagem sem URL definida" "Carregando imagem" "Falha ao carregar imagem"; do
  case "$HTTP_BODY" in *"$s"*) pass "1.3 bundle publicado contém \"$s\"";; *) fail "1.3 bundle publicado contém \"$s\"" "o hml não está servindo o artefato das F1–F4";; esac
done

section "2. caso A — host COM ACAO, via proxy (DoD 18)"
fetch "$(proxy_url "$URL_A")" -H "Origin: $WEB_BASE"
check "2.1 proxy(URL_A) -> 200" "200" "$HTTP_STATUS" "body=$(head -c 120 "$TMP/body" | tr -d "\\0")"
contains "2.2 content-type de imagem" "image/" "$(header content-type)"
check "2.3 ACAO é a origem do EDITOR (não '*' — o proxy não é rota pública, D11)" "$WEB_BASE" "$(header access-control-allow-origin)"
[ -n "$(header etag)" ] && pass "2.4 ETag presente ($(header etag | head -c 20)…)" || fail "2.4 ETag presente"
contains "2.5 Cache-Control com must-revalidate" "must-revalidate" "$(header cache-control)"
contains "2.6 X-Content-Type-Options: nosniff" "nosniff" "$(header x-content-type-options)"

section "3. caso B — host SEM ACAO: o caso do relato (DoD 19)"
# 3.1 é a guarda do teste inteiro: se este host passar a servir ACAO, ele virou
# caso A e a prova do proxy some. Falhar aqui é o script se protegendo.
fetch "$URL_B" -H "Origin: $WEB_BASE"
check "3.1 URL_B responde 200 direto" "200" "$HTTP_STATUS"
check "3.2 URL_B NÃO serve access-control-allow-origin (ainda é caso B)" "" "$(header access-control-allow-origin)" \
  "se apareceu ACAO, troque URL_B por outra sem ACAO — ver §10 do plan.md"
fetch "$(proxy_url "$URL_B")" -H "Origin: $WEB_BASE"
check "3.3 proxy(URL_B) -> 200 — é a F3 entregando" "200" "$HTTP_STATUS" "body=$(head -c 120 "$TMP/body" | tr -d "\\0")"
contains "3.4 content-type de imagem" "image/" "$(header content-type)"
check "3.5 o proxy põe a ACAO que o host não punha" "$WEB_BASE" "$(header access-control-allow-origin)"
[ "$(wc -c < "$TMP/body")" -gt 100 ] && pass "3.6 corpo tem bytes de imagem ($(wc -c < "$TMP/body") B)" || fail "3.6 corpo tem bytes de imagem"
# A revalidação se mede aqui, não no caso A: `picsum.photos/300/200` devolve uma
# imagem DIFERENTE a cada request, então o ETag (hash do corpo) nunca se repete.
ETAG_B="$(header etag)"
fetch "$(proxy_url "$URL_B")" -H "Origin: $WEB_BASE" -H "If-None-Match: $ETAG_B"
check "3.7 revalidação com If-None-Match -> 304" "304" "$HTTP_STATUS"

section "4. caso C — URL inexistente (DoD 20)"
fetch "$(proxy_url "$URL_C")" -H "Origin: $WEB_BASE"
check "4.1 proxy(URL_C) -> 502" "502" "$HTTP_STATUS" "body=$HTTP_BODY"
check "4.2 erro sem oráculo: mensagem genérica" "Não foi possível obter a mídia solicitada." "$(jqr '.message')"
check "4.3 ACAO presente também no erro (o Flutter precisa LER o erro para exibi-lo)" "$WEB_BASE" "$(header access-control-allow-origin)"
# O texto do motivo que o editor exibe vem da NetworkImageLoadException, que
# embute a URL buscada — a do proxy. É esperado (§10, aviso 2).
pass "4.4 (nota) o motivo na tela citará $API_BASE/media/proxy?url=… — esperado, não é bug"

section "5. bordas do endpoint que a tela não alcança"
fetch "$API_BASE/media/proxy" -H "Origin: $WEB_BASE"
check "5.1 sem parâmetro url -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"
fetch "$API_BASE/media/proxy?url=" -H "Origin: $WEB_BASE"
check "5.2 url vazia -> 400" "400" "$HTTP_STATUS"
fetch "$(proxy_url "$WEB_BASE/index.html")" -H "Origin: $WEB_BASE"
check "5.3 alvo HTML (content-type não-imagem) -> 400" "400" "$HTTP_STATUS" "body=$HTTP_BODY"
# D11 no caminho do cliente: o proxy NÃO nasce sob /v1/public, então o app
# publicado não tem como cair nele nem por engano.
fetch "$API_BASE/public/media/proxy?url=$(urlenc "$URL_A")"
check "5.4 (D11) /v1/public/media/proxy não existe" "404" "$HTTP_STATUS" "status=$HTTP_STATUS"

section "6. spec — compatibilidade e as props novas da F4 (DoD 25)"
resolve_category
[ -n "$CATEGORY_ID" ] && pass "6.0 categoria de destino resolvida ($CATEGORY_ID)" || fail "6.0 categoria de destino resolvida"
req POST "/contents" -H 'content-type: application/json' \
  -d "$(jq -nc --arg n "$NAME" --arg s "$SLUG" --arg c "$CATEGORY_ID" '{name:$n, slug:$s, description:"E2E do item 39", categoryId:$c}')"
check "6.1 criar conteúdo -> 201" "201" "$HTTP_STATUS" "body=$HTTP_BODY"
CREATED_ID="$(jqr '.id')"
[ -n "$CREATED_ID" ] && [ "$CREATED_ID" != "null" ] && pass "6.2 id retornado ($CREATED_ID)" || { fail "6.2 id retornado" "body=$HTTP_BODY"; echo "sem id — abortando"; exit 1; }

LEGADO="$(image_node "$(jq -nc --arg s "$URL_A" '{src:$s, width:200, height:120}')")"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' -d "$(jq -nc --argjson spec "$(spec "$LEGADO")" '{spec:$spec}')"
check "6.3 spec ANTIGO (width numérico 200) continua válido" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "6.4 reabre com o width numérico intacto" "200" "$(jqr '.spec.root.props.width')"

NOVO="$(image_node "$(jq -nc --arg s "$URL_A" '{src:$s, width:"100%", height:180, fit:"cover", alignment:"topLeft", borderRadius:16, backgroundColor:"#FF00AAFF", semanticLabel:"Foto de teste"}')")"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' -d "$(jq -nc --argjson spec "$(spec "$NOVO")" '{spec:$spec}')"
check "6.5 spec NOVO (width \"100%\" + props da F4) aceito" "200" "$HTTP_STATUS" "body=$HTTP_BODY"
req GET "/contents/$CREATED_ID"
check "6.6 width percentual preservado" "100%" "$(jqr '.spec.root.props.width')"
check "6.7 alignment preservado" "topLeft" "$(jqr '.spec.root.props.alignment')"
check "6.8 borderRadius preservado" "16" "$(jqr '.spec.root.props.borderRadius')"
check "6.9 backgroundColor preservado" "#FF00AAFF" "$(jqr '.spec.root.props.backgroundColor')"
check "6.10 semanticLabel preservado" "Foto de teste" "$(jqr '.spec.root.props.semanticLabel')"
check "6.11 round-trip byte-a-byte" "$(spec "$NOVO" | jq -S -c .)" "$(jqr '.spec' | jq -S -c .)"

SEM_SRC="$(image_node '{}')"
req PUT "/contents/$CREATED_ID" -H 'content-type: application/json' -d "$(jq -nc --argjson spec "$(spec "$SEM_SRC")" '{spec:$spec}')"
check "6.12 image sem src continua um spec válido (o estado \"vazio\" é legítimo)" "200" "$HTTP_STATUS" "body=$HTTP_BODY"

section "7. limpeza"
req DELETE "/contents/$CREATED_ID"
check "7.1 DELETE -> 204" "204" "$HTTP_STATUS"
req GET "/contents/$CREATED_ID"
check "7.2 GET após delete -> 404" "404" "$HTTP_STATUS"
CREATED_ID=""

section "Resumo"
printf '%sPASS=%d%s  %sFAIL=%d%s\n' "$g" "$PASS" "$o" "$r" "$FAIL" "$o"
printf '%sA matriz de segurança do proxy (§11.4, 27–44) NÃO é refeita aqui: roda como suíte e2e do Nest, no CI.%s\n' "$d" "$o"
if [ "$FAIL" -gt 0 ]; then printf '%sFalhas:%s %s\n' "$r" "$o" "${FAILED[*]}"; exit 1; fi
echo "${g}Tudo verde contra ${API_BASE}.${o}"
