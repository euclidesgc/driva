# plan.md — Item 27: Storage S3/Garage ligado

> Documento de planejamento. Dono na execução: **especialista-infra**. Base: `docs/roadmap.md` › Marco 6.
> Regra do "pronto": **`pnpm build`/`pnpm lint` verdes + imagem sobrevivendo a um redeploy do hml** (é o teste que importa aqui).
> **Gate CISO**: credenciais, exposição de key e cache de binário.

## 1. Objetivo e o que este item **não** é

**Descoberta ao levantar o código (2026-08-13): o adapter S3 já está pronto e completo.** `backend/src/storage/s3-storage.service.ts` implementa `put`/`get`/`delete` com `@aws-sdk/client-s3`, `forcePathStyle: true` (exigência de Garage/R2), UUID no nome, `S3_KEY_PREFIX` para namespacear ambiente, e o `storage.module.ts` já escolhe o adapter por `STORAGE_DRIVER`. O `.env.example` já documenta cada variável, inclusive o endpoint do Garage do projeto.

Ou seja: **este item não é "implementar storage". É ligar, migrar o que existe, provar que aguenta e fechar dois buracos que só aparecem quando se liga.** Escrever isso claramente evita que a feature seja dimensionada como se fosse grande — e evita reimplementar o que já está feito.

**Entra:**
1. Provisionar bucket + credenciais no Garage e configurar as envs no Coolify (ação humana).
2. Migrar os objetos que existirem em `.storage/` para o bucket, preservando as keys.
3. **Fechar o buraco da persistência**: hoje, em hml, `STORAGE_LOCAL_DIR=.storage` grava **dentro do container** — a menos que exista volume, toda imagem de projeto some no próximo deploy. Confirmar e registrar.
4. **Fechar a colisão com o item 26** (ver §3, D3): o endpoint de imagem não sobrevive ao guard global do jeito que está.
5. Falhar cedo e alto se a credencial estiver errada (hoje o erro só aparece no primeiro upload).
6. Cache do binário servido.

**Fica fora:** CDN na frente do bucket, URL assinada com redirect 302 (registrado em §8), upload de mídia dentro do conteúdo SDUI (hoje o único uso é a capa do projeto — quando o catálogo ganhar upload de imagem por widget, este port já atende sem mudança).

## 2. Precedências

| O que já existe | Onde | Estado |
| --- | --- | --- |
| `StorageService` (port abstrato: `put(buffer, contentType, prefix)`, `get(key)`, `delete(key)`) | `backend/src/storage/storage.service.ts` | **Pronto.** Não muda. |
| `S3StorageService` completo (endpoint, bucket, credenciais, região `auto`, `forcePathStyle`, `keyPrefix`, `extensionFor`) | `backend/src/storage/s3-storage.service.ts` | **Pronto.** Só ganha o health check da F3. |
| `LocalStorageService` com defesa contra traversal e `.meta` para content-type | `backend/src/storage/local-storage.service.ts` | **Pronto.** Vira só o driver de dev. |
| Escolha por `STORAGE_DRIVER` (`local`/`s3`), erro claro em driver inválido | `backend/src/storage/storage.module.ts` | **Pronto.** |
| Pipeline de upload seguro (magic bytes, allowlist png/jpeg/webp, reencode com sharp, `MAX_UPLOAD_BYTES`) | `backend/src/projects/image-pipeline.ts` | **Pronto**, aprovado pelo CISO na feature 09. |
| `ProjectsService` gravando `imageKey` com rollback do objeto órfão no catch (linhas 59–97) e `imageUrl` derivado (`/v1/projects/:id/image`, linha 224) | `backend/src/projects/projects.service.ts` | Muda só se adotarmos a rota por key (D3). |
| `GET /v1/projects/:id/image` com `X-Content-Type-Options: nosniff` e content-type fixado | `backend/src/projects/projects.controller.ts:110` | Alvo da D3. |
| Envs documentadas (`STORAGE_DRIVER`, `S3_*`, endpoint do Garage `s3.bmjtech.duckdns.org`, região `garage`) | `backend/.env.example` | **Pronto.** |
| Decisão do humano de 2026-07-09: storage = **Garage**, key `<projectId>/midias/<uuid>.<ext>` | `docs/09-crud-projeto/variance_report.md` | Travada. |

## 3. Decisões

**D1 — `S3_KEY_PREFIX` por ambiente, obrigatório.**
`driva-hml` e `driva-prod` no mesmo bucket, ou buckets separados — **escolher agora**. Recomendação: **bucket único + `S3_KEY_PREFIX` distinto**, porque o Garage do projeto já é compartilhado e criar bucket por ambiente multiplica a gestão de credencial. Consequência: a credencial de hml consegue ler prod se souber a key. Se isso incomodar, buckets separados com chaves separadas — decisão do humano (§7).

**D2 — Migração preserva as keys.**
O script de migração **não** usa `StorageService.put` (que gera key nova por UUID): usa o `S3Client` direto para gravar cada objeto **na mesma key** que já está em `Project.imageKey`. Motivo: qualquer key nova exigiria `UPDATE` no banco e abriria janela de inconsistência. Preservando a key, a migração é idempotente e o banco não é tocado.

**D3 — O endpoint de imagem passa a ser por key opaca, `@Public()`.**  ← **descoberta da revisão cruzada com o item 26**
Hoje a imagem é servida em `GET /v1/projects/:id/image` e consumida pelo editor como URL simples (`imageUrl` no `toSummary`). Um `<img src>`/`Image.network` **não manda header `Authorization`**. Quando o item 26 ligar o guard global, **toda capa de projeto quebra** — e a "solução" apressada (marcar a rota como pública) exporia a imagem de qualquer projeto por id enumerável.

Solução proposta, que resolve os dois problemas de uma vez:
- Rota nova **`GET /v1/media/:key`** (`@Public()`), onde `key` é a key opaca do storage (`<projectId>/midias/<uuid>.<ext>` — o UUID é a parte não-adivinhável). Mantém `nosniff` e content-type fixado.
- `imageUrl` no `toSummary` passa a apontar para `/v1/media/<imageKey>`.
- `GET /v1/projects/:id/image` continua existindo por um ciclo (redirecionando 301 para a nova), para não quebrar cache/links, e é removido depois.
- Segurança: a key contém o `projectId`, então **não é secreta sobre "qual projeto"** — mas o UUID a torna não-enumerável, que é exatamente o modelo de "unguessable URL" que o CISO já aprovou para o nome do arquivo.

> **Se o item 26 for executado antes do 27**, esta rota precisa nascer lá. O plano 26 foi anotado com essa costura.

**D4 — Cache no serving.**
Objeto sob key com UUID é imutável por construção (trocar a imagem gera key nova). Então: `Cache-Control: public, max-age=31536000, immutable` + `ETag` pela key. Isso derruba o custo do proxy (o backend deixa de buscar no S3 a cada render de lista) sem precisar de CDN.

**D5 — Falhar no boot, não no primeiro upload.**
O `S3StorageService` já lança se faltar `S3_BUCKET`/chaves, mas **não** valida que a credencial funciona. Acrescentar um `HeadBucketCommand` no `onModuleInit` (log de erro alto + processo continua? **não**: derrubar o boot, no mesmo espírito do `JWT_SECRET` do item 26). Motivo: subir "saudável" e só descobrir no primeiro upload do usuário é o pior modo de falha.

## 4. Fases

### F0 — Provisionamento (ação humana, bloqueia tudo)

Não é código. Checklist:
1. Criar bucket no Garage (`s3.bmjtech.duckdns.org`) e a chave de acesso com permissão **só** nesse bucket.
2. Definir `S3_KEY_PREFIX` de hml e de prod (D1).
3. Cadastrar no Coolify, como env/Build Variable do backend: `STORAGE_DRIVER=s3`, `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION=garage`, `S3_KEY_PREFIX`.
4. **Não** commitar nada disso. Atualizar `docs/deploy/coolify.md` com a lista (sem valores).

### F1 — Diagnóstico e trava da persistência atual  **[∥ com F0]**

**Por quê.** Antes de migrar, saber o que existe — e o que talvez já tenha sido perdido.

**Passos:**
1. Conferir no Coolify se o deployable do backend tem **volume** montado em `.storage`. Se não tiver, as imagens de hml já somem a cada deploy: registrar isso no `variance_report` da feature e comunicar (é achado, não culpa).
2. Rodar no hml uma contagem: `SELECT count(*) FROM projects WHERE image_key IS NOT NULL` **versus** quantos arquivos existem em `.storage/`. A diferença é o estrago.
3. Se houver divergência, decidir com o humano: limpar `image_key` órfão (a capa vira o gradiente default que o `cover_placeholder.dart` já desenha) ou pedir reupload.

**Entrega:** uma nota curta em `docs/27-storage-garage/diagnostico.md` com os números.

### F2 — Script de migração  **[depende de F0]**

**Arquivo a criar:** `backend/scripts/migrate-storage-to-s3.ts` (executável por `pnpm tsx`, **fora** do `src/` para não entrar no bundle da app).
- Lê `STORAGE_LOCAL_DIR`, varre recursivamente, para cada par `<arquivo>`/`<arquivo>.meta` faz `PutObjectCommand` com a **mesma key** (D2) e o content-type do `.meta`.
- **Idempotente:** `HeadObjectCommand` antes; se já existe com o mesmo tamanho, pula.
- **Dry-run por default** (`--apply` para escrever de verdade). Imprime o resumo: copiados / pulados / falhos.
- Não toca o banco. Não apaga o local (a limpeza é manual, depois da verificação).

**Critério de aceite:** rodar duas vezes seguidas com `--apply` produz o mesmo estado e zero erro.

### F3 — Backend: health check, rota de mídia e cache  **[depende de F0; ∥ com F2]**

**Arquivos a modificar:**
- **`backend/src/storage/s3-storage.service.ts`** — implementar `OnModuleInit` com `HeadBucketCommand`; erro → `throw` (D5). Atualizar o dartdoc do topo, que hoje diz "pronto e codado, mas **não ativado**" — vira mentira depois desta feature.
- **`backend/src/storage/storage.module.ts`** — atualizar o comentário que manda "não ligar em hml/prod sem a Decisão 4": a decisão **foi tomada** (Garage, 2026-07-09).
- **`backend/.env.example`** — mesma limpeza de texto.

**Arquivos a criar (D3):**
- **`backend/src/media/media.controller.ts`** + **`media.module.ts`** — `@Controller('media')`, `@Get(':key(*)')` (curinga: a key tem barras), `@Public()` **se o item 26 já existir**, `nosniff`, content-type do storage, `Cache-Control` + `ETag` (D4), 404 quando `get` devolve `null`.
  > **Validação obrigatória da key** antes de chamar o storage: aceitar só `[A-Za-z0-9_\-./]` e recusar `..`. O `LocalStorageService` já tem defesa própria (`resolveWithinBase`), mas o adapter S3 **não** — uma key com `..` é aceita pelo S3 como nome literal, então o risco real não é traversal, é servir objeto de outro prefixo. Barrar na borda.
- **`backend/src/projects/projects.service.ts`** — `imageUrl` passa a `/v1/media/${row.imageKey}` (linha 224).
- **`backend/src/projects/projects.controller.ts`** — `GET :id/image` vira redirect 301 para a nova rota (um ciclo), e some depois.

**Critério de aceite:**
- Boot com credencial errada **falha** com mensagem clara.
- `GET /v1/media/<key válida>` devolve a imagem com `Cache-Control: immutable` e `ETag`; segunda chamada com `If-None-Match` → 304.
- `GET /v1/media/../../etc/passwd` → 400.
- Editor mostra as capas normalmente (nenhuma mudança no Flutter é necessária: `imageUrl` já vem pronto do backend — **confirmado** em `project_model.dart`/`toSummary`).

### F4 — Virada em homologação

1. Deploy com `STORAGE_DRIVER=s3` **depois** da F2 aplicada.
2. Upload de capa nova → conferir o objeto no bucket, no prefixo certo.
3. **Redeploy** e conferir que a capa continua lá — o teste que define o sucesso deste item.
4. Excluir projeto arquivado (item 9e) → conferir que o objeto sumiu do bucket (o `delete` do service é chamado na cascata? **verificar**: se a exclusão de projeto não chama `storage.delete`, fica lixo no bucket para sempre — provável achado, corrigir aqui).

### F5 — Testes

- Unit do `media.controller` (validação de key, 404, 304).
- Unit do script de migração com um `S3Client` fake.
- E2E de contrato: upload → `imageUrl` → GET 200 → delete do projeto → GET 404.
- **Não** criar teste que fale com o Garage real na CI (credencial no CI = superfície nova). O E2E contra o Garage é manual, no hml.

## 5. Mapa de paralelismo

```
F0 (humano) ──┬─► F2 (script) ──┐
              └─► F3 (backend) ─┴─► F4 (virada) ─► F5 (testes)
F1 (diagnóstico) ─────────────────┘   (F1 é independente e pode ser a primeira coisa)
```

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 26 (auth) — colisão real encontrada e resolvida aqui (D3).** O guard global quebraria as capas de projeto. **Ação:** o plano 26 recebe uma nota apontando para esta D3; qual dos dois itens executar primeiro define onde a rota `/v1/media/:key` nasce. Nenhum dos dois planos pode assumir que o outro já resolveu.
- **Item 25 (entrega ao app) — nenhuma colisão hoje**, mas há uma dependência futura: quando um widget SDUI publicado referenciar uma imagem do storage, a URL precisa ser alcançável **pelo app do cliente**, que não tem sessão. A rota `/v1/media/:key` pública (D3) já atende — e é mais um motivo para adotá-la.
- **Item 24 — sem contato.**
- **Item 9e (exclusão de projeto)** — a F4 checa se a cascata apaga o objeto. Se não apagar, é correção pertencente a este item (o lixo só passa a custar dinheiro quando o storage é remoto).

## 7. Perguntas para o humano (bloqueiam a F0)

1. **Bucket único com prefixo por ambiente, ou bucket por ambiente?** (D1 — recomendo prefixo; buckets separados isolam melhor.)
2. **Existe volume montado hoje no `.storage` do hml?** Se não, confirmar o descarte das capas atuais (F1).
3. **Quota/limite de tamanho do bucket no Garage** — precisa de política de retenção?

## 8. Deixado de fora (registro)

Redirect 302 para URL assinada (elimina o proxy, custa expiração e complica cache) · CDN na frente · thumbnails/variantes por tamanho · antivírus no upload (o pipeline já reencoda com sharp, que neutraliza a maioria dos payloads) · storage de mídia usada dentro do spec SDUI (chega junto com o widget de upload, no item 9).
