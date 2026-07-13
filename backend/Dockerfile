# syntax=docker/dockerfile:1
# Backend NestJS — imagem de deploy (Coolify).
# Contexto de build = ./backend  (Base Directory /backend no Coolify).

# ---- build ----
FROM node:20-alpine AS build
WORKDIR /app
# CI=true: garante instalação não-interativa (evita prompt de TTY do pnpm).
ENV CI=true
RUN corepack enable && corepack prepare pnpm@10.24.0 --activate

# Dependências primeiro (cache): manifests antes do código.
#
# `sharp` (upload de imagem de Project — F2) tem binário nativo via
# optionalDependency `@img/sharp-linuxmusl-x64`: como este estágio JÁ roda em
# node:20-alpine (musl), `pnpm install` aqui resolve e baixa o pacote musl
# certo sozinho — sem apk extra (libvips vem estático dentro do pacote) e sem
# build script (sharp não usa postinstall compilado, só o optional pré-built).
# Testado manualmente: instalar este lockfile dentro de node:20-alpine puro
# carrega `sharp` sem erro. Se um dia sharp mudar de estratégia de distribuição
# e passar a exigir build script, rodar `pnpm approve-builds` e listar aqui.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# Código e build (gera o Prisma Client e compila o Nest).
COPY . .
RUN pnpm prisma:generate && pnpm build

# ---- runtime ----
FROM node:20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.24.0 --activate

# node_modules inteiro (inclui a CLI do Prisma, devDep, usada no start).
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/docker-entrypoint.sh ./docker-entrypoint.sh

EXPOSE 3000

# Aplica as migrations versionadas no start e sobe — via `docker-entrypoint.sh`,
# que loga cada passo e, se `migrate deploy` falhar, imprime `migrate status`
# (qual migration falhou/pendente) antes de abortar. Motiva: o container do
# backend do #43 morria "no escuro" no start e o Coolify mantinha a imagem
# anterior no ar (`/v1/projects` 404 em hml).
#
# Adoção do Prisma Migrate sobre um banco criado por `db push` (hml/prod): o
# `migrate deploy` sozinho aborta com P3005 ("schema não vazio, sem histórico").
# Por isso o entrypoint registra a baseline (`0_baseline` = estado já deployado)
# ANTES do deploy (idempotente). Se `migrate deploy` falhar, o container aborta
# com código != 0 (o Coolify marca o deploy como falho).
# DATABASE_URL / PORT / CORS_ORIGINS vêm do ambiente (Coolify), nunca do repo.
CMD ["sh", "./docker-entrypoint.sh"]
