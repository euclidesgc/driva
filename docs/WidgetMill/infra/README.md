# infra/

Infraestrutura de desenvolvimento.

- **docker-compose.yml** — Postgres + Redis para dev (usados a partir do M3).
- **prisma/** — `schema.prisma`, migrations e `seed.ts` (modelo de dados, provisionamento multi-tenant). *(M3)*

```bash
docker compose -f infra/docker-compose.yml up -d
```
