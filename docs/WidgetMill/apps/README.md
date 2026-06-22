# apps/

Aplicações executáveis. Dependem de `packages/spec`, nunca o contrário; `web` e `api` conversam por HTTP (não se importam).

- **web/** — Next.js (App Router): editor visual (Puck) + telas de gestão. *(M2)*
- **api/** — NestJS: identidade, RBAC, workflow, versionamento, catálogo. *(M3)*
