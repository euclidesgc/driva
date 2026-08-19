# Relatório final — Publicação e versionamento de conteúdo

_Item 24 do roadmap. 2026-08-17. PR #161 (`feature/24-p1-backend-publicacao → develop`)._

## O que ficou pronto

**Rascunho × publicado, de verdade.** `Content.spec` virou `draftSpec` (migração
`RENAME COLUMN`, nenhum spec perdido) e nasceu `ContentVersion` — histórico
imutável, sem poda, sem backfill retroativo (D2: nada estava publicado antes
desta feature).

| Rota | Comportamento |
| --- | --- |
| `POST /contents/:id/publish` | Carimba a próxima versão a partir do `draftSpec` do servidor (nunca do corpo da requisição). Idempotente (D3): sem mudança desde a última publicação, devolve a versão atual em vez de duplicar. |
| `POST /contents/:id/unpublish` | Tira do ar sem apagar nada. |
| `GET /contents/:id/versions` | Paginação por cursor, mesmo padrão keyset do resto da API. |
| `POST /contents/:id/versions/:version/restore` | Traz uma versão antiga de volta para o **rascunho** — nunca republica direto (D4). |

**Fecha o débito VR-13-01.** A API pública (`/v1/public/contents`) passa a
servir a versão **publicada** via `publishedVersionId`, não mais o rascunho.
Conteúdo nunca publicado ou despublicado não aparece; o `ETag` reflete
`publishedAt`, então autosave do rascunho não invalida o cache de quem já
consome a versão no ar.

**Editor.** Botão "Publish" real (diálogo de confirmação, `note` opcional,
contagem de avisos), bloqueado — com o motivo certo no tooltip — enquanto
houver diagnóstico de erro no documento. O topo mostra três estados ("No ar
(vN)" / "Alterações não publicadas" / "Nunca publicado"), com edição em
conteúdo publicado reacendendo o estado na hora, sem esperar reload. Diálogo
de histórico paginado, com restaurar. Selo na lista de conteúdos, sem request
extra. Falha de rede em publicar, despublicar ou restaurar produz um estado
**visualmente distinto** do sucesso (barra de status, ícone + texto).

## Como esta sessão chegou aqui

P1–P4 foram implementadas antes desta sessão (working dir, não commitada).
Esta sessão: revisou tudo com QA + CISO (duas rodadas cada), corrigiu 6 bugs
reais achados na revisão, instrumentou o E2E, escreveu a bateria automatizada
do P5, e validou contra homologação real antes do fechamento.

### Bugs corrigidos na revisão (antes do merge)

1. **Backend — `publish()`/`unpublish()` não devolviam `hasUnpublishedChanges`**, e o `PublicationStateModel` do editor exige a chave — todo publish real teria caído em `publishFailed` contra o backend de verdade (só o fake mascarava).
2. **Migração com drift** — `draft_updated_at` ficava com `DEFAULT` permanente sem `@default` no schema; corrigido com `DROP DEFAULT` explícito no fim da mesma migração.
3. **Skew de relógio** — `publishedAt` vinha do `now()` do Postgres e `draftUpdatedAt` do `new Date()` do Node; unificado num único `now` por publicação.
4. **Falha de publish/unpublish/restore era invisível** — `PublishStatus` era escrito e nunca lido por nenhum widget; `restoreVersion` descartava o `Left` em silêncio e o diálogo de histórico fechava como se tivesse dado certo. Corrigido com `EditorNoticeKind` novo por operação, na barra de status (item 8e).
5. **Tooltip do botão Publish mentia** quando desabilitado por `saving`/`publishing` (dizia sempre "corrija os erros"). Corrigido com `PublishBlockReason`.
6. **Topo não refletia edição em conteúdo já publicado** até reload — corrigido marcando `hasUnpublishedChanges` no funil de mutação do documento.

Detalhe de cada um e a numeração formal dos desvios: `variance_report.md`.

## Evidências

**E2E de contrato, contra `https://api-hml.driva.duckdns.org` (não localhost —
lição do item 9g):** `docs/24-publicacao-versionamento/e2e_hml.sh` —
**103/103 PASS**. Cobre os 8 casos do §4/P1 do plano, mais idempotência,
paginação, cross-tenant (404 nunca 403), bordas de validação, cascade na
exclusão de conteúdo, **e a regressão do item 9e** (exclusão de projeto com
conteúdo publicado).

**E2E de UI, contra `https://hml.driva.duckdns.org`:**
`docs/24-publicacao-versionamento/e2e_shots.sh 01` — **35/35 PASS**, 18
prints em `evidencias/rodada_01/` (README com a tabela sucesso×falha e o
porquê de cada print). Publicar → selo muda na lista sem reload → histórico
abre sem reconstruir o canvas → restaurar → republicar o rollback →
despublicar. **Os dois modos de falha do item foram provocados de verdade**
(rota cortada por CDP) e capturados: `13_publish_falhou.png` mostra o topo
continuando em laranja ("Alterações não publicadas", não mentindo sucesso) e
o rodapé com "Falha ao publicar. Tente novamente." em vermelho — contra
`04_topo_no_ar_v1.png`, onde o mesmo topo fica verde e o rodapé limpo.

**Bateria automatizada:** 469 testes no editor (29+ novos desta sessão:
`publish`/`unpublish`/`restoreVersion` no cubit, `VersionHistoryCubit`,
models, `publish_dialog`, `PublicationBadge`), todos verdes. `flutter
analyze` sem issues. Backend: `pnpm build`/`pnpm lint` verdes, `pnpm test`
5/5.

**Migração em hml:** aplicada automaticamente no deploy (`prisma migrate
deploy` no start do container, `docs/deploy/coolify.md`). Conferido por API
antes/depois: o conteúdo pré-existente (`home de IR`, projeto `default`)
manteve o `spec` intacto, ganhou `publishedAt: null` / `hasUnpublishedChanges:
true` — exatamente o D2 (nada publicado retroativamente).

## O que a validação em hml revelou (fora do escopo deste item)

Rodar o E2E contra dado real de homologação — não um seed fresco — expôs
dois bugs pré-existentes, sem relação com publicação/versionamento:

1. **`ProjectScope` não sobrevive a um F5** (item **46** do roadmap): a rota
   `/contents/:id/edit` não carrega `projectId` na URL, e o estado que
   escopa o `x-project-id` é só em memória. Recarregar o editor (ou abrir um
   link direto) num projeto que não é o `default` mostra "Conteúdo não
   encontrado" — mensagem enganosa, o conteúdo existe. Só não afeta o
   projeto `default` por coincidência de valor de fallback. Descoberto
   porque o driver do E2E de UI usa `Page.navigate` (reload completo, como
   um F5) entre as telas. **Corrigido pelo item 46 em 2026-08-18:** a rota
   virou `/projects/:projectId/contents/:id/edit`
   (`docs/46-projectid-na-rota-do-editor/`).
2. **A categoria "Geral" pode ser renomeada**, e o fallback de criação de
   conteúdo sem `categoryId` explícito busca por esse nome literal (item
   **47**). No projeto `default` de hml, "Geral" foi renomeada em uso real —
   e criar conteúdo sem categoria explícita passou a devolver 400. Os
   scripts de E2E deste item foram corrigidos para passar `categoryId`
   explícito (buscado via `GET /categories`) em vez de depender do nome.

Nenhum dos dois bloqueou este item — os scripts foram ajustados, e os
achados foram registrados no roadmap para correção própria.

## Como testar de novo

```bash
docs/24-publicacao-versionamento/e2e_hml.sh                      # contrato, 103 PASS
docs/24-publicacao-versionamento/e2e_shots.sh 02                 # próxima rodada de prints
```

Os dois são idempotentes e auto-limpantes — criam um conteúdo de teste
(`slug: e2e-24-publicacao`) no projeto `default` e o apagam ao fim, além de
um projeto descartável para os casos de cross-tenant/exclusão.

## Pendências assumidas

- Itens 46 e 47 do roadmap (bugs pré-existentes, não deste item).
- Item 45 do roadmap: barra de topo/rodapé do editor sem árvore de
  acessibilidade (pré-existente; limitou o driver do E2E de UI a varredura
  de clique + fingerprint de pixel em vez de leitura semântica).
- `draftSpec` lido fora da `$transaction` em `publish()` — janela de
  consistência mínima, aceita pelo CISO (`variance_report.md` VR-24-02).
- `createdBy` de `ContentVersion` nasce nullable e segue sem preenchimento
  até o item 26 (autenticação) existir — decisão do próprio plano (D1).
