# test_plan.md — Item 24: publicação e versionamento

Instrumentação do E2E (QA, etapa 10 do fluxo). **Nada aqui vai para produção.**

## 1. O que a máquina valida

| Script | O que cobre | Como roda |
| --- | --- | --- |
| `e2e_hml.sh` | O contrato inteiro do §4/P1 do `plan.md`, por API: ciclo de vida, idempotência (D3), lista de versões e paginação por cursor, API pública servindo o publicado (D6/ETag), restore (D4), cross-tenant, bordas de validação, unpublish, cascade das versões e a regressão do item 9e. **102 asserções.** | `docs/24-publicacao-versionamento/e2e_hml.sh` |
| `e2e_shots.sh` + `e2e_drive.mjs` | O fluxo na tela, headless por CDP, com asserção por API depois de cada passo: selo da lista, publicar (v1→v2), histórico, restaurar, republicar o rollback, despublicar — **mais os dois modos de falha** (`publishFailed`, `restoreFailed`), provocados cortando a rota por CDP. **35 asserções + 18 prints.** | `docs/24-publicacao-versionamento/e2e_shots.sh 01` |

Ambos apontam para **homologação** por default (`BASE_URL`/`WEB_BASE`/`API_BASE` sobrescrevem).

## 2. O que sobra para o olho do dev

Abrir `evidencias/rodada_NN/README.md` e conferir as 18 imagens. O README traz,
por print, o que o script já provou e o que só o olho prova. O ponto central é a
tabela dos **dois modos de falha**: publicar/restaurar que falham têm de ser
inconfundíveis com os que dão certo.

## 3. Rastro a limpar no wrap

**Nenhuma instrumentação de código foi necessária** — a stack real existe, os
scripts falam com ela por HTTP/CDP. Não há fake, não há `log('[e2e] …')`, não há
`// TODO remover`. O que os scripts criam, eles apagam:

| Rastro | Quem remove |
| --- | --- |
| 1 conteúdo com slug `e2e-24-publicacao` no projeto alvo | os dois scripts, no início e no fim |
| 1 projeto descartável `E2E 24 cross-tenant <ts>` (+ o conteúdo dentro dele) | `e2e_hml.sh`, no `trap EXIT` |
| Chrome headless + `--user-data-dir` temporário | `e2e_shots.sh`, no `trap EXIT` |
| `$TMP` do `mktemp -d` | `e2e_hml.sh`, no `trap EXIT` |

Os dois são idempotentes: rodar N vezes seguidas não precisa de limpeza manual.

## 4. Verificação prévia (não substitui o DoD)

Antes de existir deploy do branch, os scripts foram exercitados contra uma
stack local descartável (Postgres efêmero em container próprio + backend do
branch + build web servido com fallback de SPA):

- `e2e_hml.sh` → **102 PASS / 0 FAIL**, duas execuções seguidas, zero rastro no banco.
- `e2e_drive.mjs` → **35 PASS / 0 FAIL**, 18 prints.

**Isso não fecha o DoD**: o item exige as duas execuções contra o **hml real**,
com as evidências em `evidencias/rodada_01/`.

## 5. Achados (decisão do tech-lead, não do QA)

### A1 — O topo do shell e o rodapé do editor não existem na árvore de acessibilidade

Reproduzível: com semântica ligada, `document.querySelectorAll('flt-semantics')`
não tem **nenhum** nó acima de `y = 86` (top bar + breadcrumbs) nem na faixa do
rodapé do editor. Some dali: os botões Salvar/Publish/⋮, o indicador
`Semantics(liveRegion: true, label: 'Status: No ar (v3)')` do
`AppShellStatusIndicator`, e o `StatusBarNotice` com
`Semantics(liveRegion: true, label: 'Erro: Falha ao publicar…')`. Os diálogos e o
corpo da página expõem semântica normalmente.

Hipótese: a casca do shell é pintada **antes** da barreira de rota do
`Navigator` (`ModalBarrier` → `BlockSemantics`), que derruba a semântica de tudo
que foi pintado antes dela. É anterior ao item 24 (vale para toda rota), mas
atinge em cheio o que este item prometeu: o tooltip que explica por que o
Publish está desabilitado e os dois avisos de falha são **invisíveis para
leitor de tela** — o sinal fica só na cor e no ícone desenhados no canvas.

Efeito no E2E: o driver não consegue asserir o texto do topo nem do rodapé.
Contorna com clique varrido e verificado (a faixa de ações desliza com a largura
do texto de status) e com impressão digital de faixa de pixels — prova que
mudou/não mudou, nunca o que está escrito. Corrigido o A1, esses dois contornos
podem sair do `e2e_drive.mjs` e virar asserção de rótulo.

### A2 — O indicador do topo só conhece "alterações não publicadas" depois de recarregar

`EditorReady.publication` vem do servidor e nunca é recalculado no cliente:
`save()` não o toca e `restoreVersion()` também não. Consequência: o usuário
edita, salva, e o topo continua dizendo **"No ar (v2)"** — o estado
"Alterações não publicadas" só aparece ao reabrir a página. A lista de conteúdos
(que lê o summary do servidor) mostra a verdade nesse meio-tempo, então editor e
lista discordam. O mesmo vale logo depois de restaurar uma versão.

Não contradiz o `plan.md` (P3 pede os três estados, e eles existem), mas é o
tipo de mentira silenciosa que o item 24 se propôs a matar. Custo do conserto:
marcar `hasUnpublishedChanges: true` no `publication` ao emitir documento sujo.
