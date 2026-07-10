#!/bin/sh
# Entrypoint de deploy do backend (Coolify). Aplica as migrations versionadas
# ANTES de subir o Nest e — o ponto desta versao — deixa a falha VISIVEL.
#
# Contexto: o banco de hml/prod foi criado por `db push` (sem historico), entao
# registramos a baseline (`0_baseline`) uma vez e so entao `migrate deploy`. O
# `CMD` antigo fazia isso numa linha unica com `2>/dev/null` na baseline e sem
# imprimir o estado quando `migrate deploy` falhava — o container morria no
# escuro e o Coolify mantinha a imagem anterior no ar. Aqui logamos cada passo
# e, se `migrate deploy` falhar, imprimimos `migrate status` (qual migration
# falhou/esta pendente) antes de abortar com codigo != 0.
set -e

echo "==> [driva-api] registrando baseline (idempotente)"
# No 1o deploy grava 0_baseline; nos seguintes ela ja esta registrada e o
# resolve sai != 0 com "already recorded" — esperado, nao fatal.
if pnpm exec prisma migrate resolve --applied 0_baseline 2>/tmp/baseline.err; then
  echo "==> [driva-api] baseline registrada"
else
  echo "==> [driva-api] baseline ja registrada (ok): $(cat /tmp/baseline.err 2>/dev/null)"
fi

echo "==> [driva-api] prisma migrate deploy"
if ! pnpm exec prisma migrate deploy; then
  echo "!!! [driva-api] migrate deploy FALHOU — estado das migrations:"
  pnpm exec prisma migrate status || true
  echo "!!! [driva-api] abortando start. Corrija a migracao (ex.: prisma migrate resolve --rolled-back <nome> ou o dado) e re-deploye."
  exit 1
fi

echo "==> [driva-api] migrations aplicadas; subindo o Nest"
exec node dist/main.js
