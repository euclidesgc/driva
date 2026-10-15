import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

const databaseUrl = process.env.DATABASE_URL;

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  // `prisma generate` só lê o schema, por isso a CI não precisa expor uma
  // URL de banco. Com DATABASE_URL presente, os comandos de migração recebem
  // a mesma configuração explícita de antes.
  ...(databaseUrl ? { datasource: { url: env('DATABASE_URL') } } : {}),
});
