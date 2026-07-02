# syntax=docker/dockerfile:1
# Backend NestJS — imagem de deploy (Coolify).
# Contexto de build = ./backend  (Base Directory /backend no Coolify).

# ---- build ----
FROM node:20-alpine AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.24.0 --activate

# Dependências primeiro (cache): manifests antes do código.
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

EXPOSE 3000

# Ainda não há migrations versionadas: sincroniza o schema no start e sobe.
# DATABASE_URL / PORT / CORS_ORIGINS vêm do ambiente (Coolify), nunca do repo.
CMD ["sh", "-c", "pnpm exec prisma db push --skip-generate && node dist/main.js"]
