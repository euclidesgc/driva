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

EXPOSE 3000

# Aplica as migrations versionadas no start e sobe.
#
# Adoção do Prisma Migrate sobre um banco criado por `db push` (hml/prod): o
# `migrate deploy` sozinho aborta com P3005 ("schema não vazio, sem histórico").
# Por isso registramos a baseline (`0_baseline` = estado já deployado) ANTES do
# deploy. O `resolve --applied` é idempotente na prática: no 1º deploy grava a
# baseline; nos seguintes ele erra "já aplicada" (silenciado por `2>/dev/null`) e
# segue. Só então `migrate deploy` aplica a `rename_pages_to_contents` (ou vira
# no-op). O `&&` garante que o Nest só sobe se o migrate deploy suceder.
# (Banco 100% vazio/novo não usa este caminho — resolver baseline sem o schema
# faria o migrate deploy falhar de propósito; não há ambiente assim hoje.)
# DATABASE_URL / PORT / CORS_ORIGINS vêm do ambiente (Coolify), nunca do repo.
CMD ["sh", "-c", "pnpm exec prisma migrate resolve --applied 0_baseline 2>/dev/null; pnpm exec prisma migrate deploy && node dist/main.js"]
