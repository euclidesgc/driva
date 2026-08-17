# variance_report.md — Item 24 (`docs/24-publicacao-versionamento/`)

Registro dos desvios em relação ao `plan.md` desta pasta, no formato **como estava / por que
mudou / o que mudou**. Regra do CLAUDE.md: desvio do plano só entra com aprovação do humano e
registro aqui.

Numeração: `VR-24-NN`, na ordem em que os desvios acontecem.

| # | Fase | Desvio | Origem | Estado |
| --- | --- | --- | --- | --- |
| VR-24-01 | P1–P4 | Entregues num único PR, não em quatro | Retomada de sessão anterior | **Aceito** |
| VR-24-02 | P1 | `draftSpec` lido fora da `$transaction` em `publish()` | Gate CISO (segunda rodada) | **Registrado, não corrigido** |
| VR-24-03 | P1 | Os 2 "achados advisory" citados na retomada não foram localizados no código | Gate CISO (segunda rodada) | **Sem efeito** |

---

## VR-24-01 — P1 a P4 entregues como um PR só

**Origem:** o humano retomou a sessão com P1–P4 já implementadas na working dir (não
commitadas), de uma sessão anterior. A regra "1 fase = 1 PR" do `CLAUDE.md` pressupõe fases
implementadas e revisadas em sequência; aqui as quatro já existiam juntas antes de qualquer
revisão desta sessão começar.

**Por que mudou:** desmembrar retroativamente um working tree já unificado em quatro PRs
empilhados exigiria reconstruir a ordem de commits por arquivo, sem nenhum ganho de revisão
real — o QA e o CISO desta sessão já revisaram tudo de uma vez, como um corpo só. O custo de
desmembrar é alto (horas de `git add -p` + risco de quebrar a compilação intermediária, já que
P2 depende dos tipos do P1 e P3/P4 dependem do P2) e o ganho (revisão incremental) já não existe
mais.

**O que mudou:** um PR único, `feature/24-p1-backend-publicacao → develop`, contendo P1–P5
inteiros. Commits internos separam por camada (backend / editor / testes / docs) para dar
alguma granularidade ao histórico, mas não reproduzem o mapa de paralelismo do §5 do plano.

**Aprovação:** diretiva do humano (2026-08-16, sessão overnight) autoriza fluxo de PR/merge
sem confirmação adicional quando DoD, analyze e E2E estiverem verdes — cobre esta decisão.

---

## VR-24-02 — Leitura do `draftSpec` fora da `$transaction` em `publish()`

**Fase:** P1. **Origem:** achado do gate CISO (segunda rodada, pós-correções). **Estado:**
registrado, não corrigido.

### Como estava

`publish()` lê o conteúdo (`findContentOrThrow`, que inclui `draftSpec`) **antes** de entrar na
`$transaction` que cria a `ContentVersion` e atualiza `Content.publishedVersionId`/`publishedAt`.

### Por que não foi corrigido agora

Sob autosave concorrente de alta frequência, existe uma janela em que a versão publicada
carimba um `draftSpec` levemente mais antigo que o mais recente salvo entre a leitura e o
commit da transação. O CISO avaliou: **não é vazamento, não é cross-tenant, não é achado de
segurança** — é uma janela de consistência que, na prática, **nem chega a produzir estado
errado**: como `draftUpdatedAt` do save concorrente é posterior a `publishedAt` da versão
publicada, `hasUnpublishedChanges` corretamente continua `true` depois do publish, refletindo
que a última tecla não entrou naquela versão. É o comportamento esperado de qualquer sistema
sem lock otimista explícito nessa borda.

**Decisão:** manter como está. Mover a leitura para dentro da transação reduziria a janela mas
não a eliminaria (a rede entre o clique de "Publicar" e o servidor já é uma janela maior), e o
ganho não paga o custo de mudar o formato da transação numa fase já revisada duas vezes.
Registrado aqui para o próximo tech-lead que mexer em `publish()` decidir com o contexto
completo, não para bloquear esta entrega.

---

## VR-24-03 — Os "2 achados advisory" da retomada não foram encontrados

**Origem:** a mensagem de retomada desta sessão citava "CISO aprovado (gate liberado, 2
achados advisory registrados no próprio `contents.service.ts`)", de uma sessão anterior sem
histórico acessível a este agente. O CISO desta sessão leu o arquivo inteiro, linha a linha, e
**não achou nenhum comentário desse tipo** — nem `TODO`/`FIXME`/marcador equivalente.

**Efeito:** nenhum. O CISO não confiou na anotação e auditou o código real do zero, chegando a
GO por conta própria (com o achado novo do VR-24-02 registrado por cima). Duas hipóteses, sem
forma de confirmar: os achados foram resolvidos e removidos numa sessão anterior sem deixar
rastro neste relatório, ou a descrição da retomada estava imprecisa. Não bloqueou nada; registro
só para não deixar a discrepância muda.
