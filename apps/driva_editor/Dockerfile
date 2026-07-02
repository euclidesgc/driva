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
RUN flutter build web --release \
    --target lib/main_prod.dart \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=DEFAULT_PROJECT_ID=${DEFAULT_PROJECT_ID} \
    --dart-define=USE_FAKE_DATA=false

# ---- serve (nginx) ----
FROM nginx:alpine AS serve
COPY apps/driva_editor/deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/apps/driva_editor/build/web /usr/share/nginx/html
EXPOSE 80
