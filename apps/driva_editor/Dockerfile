# syntax=docker/dockerfile:1
# Frontend Flutter Web (o editor) — imagem de deploy (Coolify).
# Contexto de build = raiz do repo (Base Directory / no Coolify), porque o app
# faz parte de um pub workspace e depende de packages/sdui_core e sdui_flutter.

# ---- build (Flutter Web) ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /workspace

# Copia o workspace inteiro (pubspec raiz + packages + apps).
COPY . .

# Config de build por ambiente — injetada pelo Coolify como Build Variable.
# A URL da API é compile-time no Flutter Web; o mesmo Dockerfile gera hml ou
# prod conforme API_BASE_URL, sem trocar código.
ARG API_BASE_URL
ARG DEFAULT_PROJECT_ID=default

RUN flutter pub get
WORKDIR /workspace/apps/driva_editor
# --no-tree-shake-icons: NAO cortar a fonte de icones. Com tree-shaking o
# MaterialIcons-Regular.otf vira um subset diferente a cada build (mesmo nome
# de arquivo), entao um navegador com a fonte antiga em cache fica sem os
# codepoints de icones novos (ex.: o botao de tema virava "tofu" □). Embarcando
# a fonte COMPLETA, qualquer versao cacheada ja contem todos os icones — o bug
# nao depende mais de cache-busting nem de o usuario limpar o cache.
RUN flutter build web --release \
    --target lib/main_prod.dart \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=DEFAULT_PROJECT_ID=${DEFAULT_PROJECT_ID} \
    --dart-define=USE_FAKE_DATA=false \
    --pwa-strategy=none \
    --no-tree-shake-icons
RUN deploy/version_web_build.sh build/web
RUN cp deploy/flutter_service_worker_kill.js build/web/flutter_service_worker.js

# ---- serve (nginx) ----
FROM nginx:alpine AS serve
COPY apps/driva_editor/deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/apps/driva_editor/build/web /usr/share/nginx/html
EXPOSE 80
