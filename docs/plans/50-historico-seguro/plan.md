# Plano de gaveta - Item 50: historico seguro de publicacao

> Status: proposto em 2026-08-19. Dono tecnico: Tech Lead. Depende do item 24, ja entregue.

## Objetivo e decisoes

O Driva ja tem o modelo certo: `draftSpec` e mutavel, `ContentVersion` e imutavel e `publishedVersionId` aponta para o que esta no ar. O defeito e de interacao: hoje a unica forma de ler uma versao antiga e `Restaurar`, que escreve no rascunho antes de o usuario poder inspeciona-la.

Este item separa tres verbos:

| Verbo | Efeito no servidor | Efeito no editor | Cria versao |
| --- | --- | --- | --- |
| Ver | `GET` puro | preview somente leitura | nunca |
| Carregar no rascunho | nenhum alem do GET ja feito | substitui somente o rascunho local e fica sujo | nunca |
| Publicar | compara transacionalmente o draft com o snapshot no ar; cria snapshot se diferirem, ou reconcilia o marcador do draft se forem iguais | estado no ar muda ou fica limpo | somente se diferir da versao no ar |

O Squidex e referencia para leitura, comparacao e copia seletiva, nao para o modelo de dados. O Driva edita uma arvore SDUI, nao campos independentes. A v1 nao fara merge estrutural generico: ela copia apenas propriedades de um no com `id` e `type` iguais em ambos os specs. Inserir/remover subarvores, trocar tipo e resolver colisao de IDs exigem um contrato proprio de patch e ficam fora deste recorte; faze-los implicitamente pode corromper a hierarquia.

Fluxo alvo: abrir historico -> ver sem alterar -> comparar -> carregar versao inteira ou propriedades compativeis no rascunho local -> revisar -> salvar -> publicar. So publicar cria uma versao consumida pelo app cliente.

## Base confirmada e limites

- `Content.draftSpec`, `ContentVersion` imutavel, `publishedVersionId`, `latestVersion` e a separacao publicado/fora do ar ja existem no codigo atual.
- `GET /v1/contents/:id/versions/:version` devolve o `spec`, mas o editor nao o consome. A lista paginada continua sem `spec`.
- `POST /v1/contents/:id/versions/:version/restore` continua disponivel para compatibilidade, mas deixa de ser usado pela UI do editor. O novo `Carregar no rascunho` usa o GET ja obtido e so persiste no `PUT` de Salvar.
- Historico do Driva e de publicacoes, nao de autosaves. Nao criar tabela de eventos ou polling aqui; ator/auditoria completa depende dos itens 26 e 37.
- O rascunho ainda e last-write-wins. Este item nao tenta resolver edicao concorrente sem identidade e controle de concorrencia do item 26.

## Contrato interno congelado

```dart
class LoadedContentVersion {
  const LoadedContentVersion({required this.version, required this.spec, required this.createdAt, this.note, this.createdBy});
  final int version;
  final ContentSpec spec;
  final DateTime createdAt;
  final String? note;
  final String? createdBy;
}

enum VersionComparisonBase { draft, published }
```

`EditorRepository.getVersion(id, version)` devolve esse tipo. JSON chega ao dominio somente por `parseContentSpec`; JSON invalido, `specVersion` incompativel ou ausencia de `spec` devolvem `ValidationFailure`.

O motor puro de comparacao tera: propriedades alteradas, eventos alterados, no somente na base, no somente na candidata, tipo alterado, `safeArea` alterada e metadados de conteudo alterados. Copia seletiva requer mesmo ID e tipo, faz copia profunda somente das propriedades candidatas e preserva filhos, posicao e ID do rascunho. Eventos, `safeArea` e metadados sao sinalizados como diferencas nao copiaveis na v1.

Antes de comparar, o motor indexa os IDs de cada arvore. ID repetido em qualquer lado devolve `DuplicateNodeIdComparisonFailure`; a comparacao e bloqueada, nao ha seta e nenhum no pode ser modificado.

## Linguagem de UI

- Topo e lista exibem icone + texto: `Nunca publicado`, `No ar (vN)`, `Alteracoes nao publicadas (no ar: vN)` e `Fora do ar (ultima: vN)`.
- `Historico` e `Despublicar` viram comandos visiveis. O `more_vert` especifico sai; no compacto o overflow generico do shell recolhe as acoes uma unica vez.
- A revisao mostra selo `Somente leitura`, numero, data e nota. O `SduiView` historico fica dentro de `AbsorbPointer` e `FocusScope(canRequestFocus: false)`; toque, Tab e digitacao nao podem acionar widgets do snapshot. Abrir/fechar nao muda URL, autosave, undo, draft ou ponteiro publicado.
- `Carregar no rascunho` declara origem, substituicao apenas da memoria local e que nada vai ao ar automaticamente. Havendo mudancas locais nao salvas: `Descartar alteracoes locais e carregar` e `Cancelar`. `Salvar antes` nao e opcao, pois salvar e carregar logo depois ainda sobrescreveria o mesmo draft remoto.

## Tarefas e DoD individual

### T0 - Confirmar a base e congelar o recorte

**Precedencia:** item 24.

1. Confirmar em `develop` que `latestVersion` esta no backend, modelos e telas; se estiver somente no worktree, integrar a correcao aqui, sem criar campo duplicado.
2. Registrar a matriz draft/publicado/despublicado e a semantica de versao de publicacao no PR inicial.
3. Conferir que detalhe de versao valida `projectId` antes de ler `ContentVersion`, mantendo `404` entre projetos.

**DoD T0:** PR registra arquivos/hash da base; os quatro estados tem teste de modelo ou widget; nenhum endpoint, snapshot ou campo redundante e criado; tech lead aprovou o limite de v1.

### T1 - Promover acoes e preservar responsividade [paralela a T2]

**Precedencia:** T0.

1. Tornar `Historico` uma `AppBarAction.outlined` com icone `history`.
2. Tornar `Despublicar` visivel somente se existe versao publicada, preservando a confirmacao. Remover `EditorMoreMenuDialog` e o `more_vert` especifico.
3. Conferir `AppShellActionsOverflowMenu`: abaixo do limiar de colapso do shell (`AppSizes.topBarActionsFitWidth`), Historico, Despublicar e Publicar aparecem uma vez no overflow do shell. `Salvar`, a primeira e unica acao `filled`, permanece direto; nao mudar a regra generica do shell para favorecer Publicar.
4. Exibir `vN` na lista onde houver espaco, preservando o fallback tolerante de cache legado.

> **Decisao registrada (dono do produto, 2026-08-19): T1.3 alterado, o limiar de colapso deixa de ser 760px.**
>
> O item 3 original fixava 760px como o limiar de colapso do `AppShellActionsOverflowMenu`. `Historico` como `AppBarAction.outlined` com rotulo (T1.1, ao pe da letra — o texto do plano so pede rotulo para `Historico`, nunca para `Despublicar`) faz a barra (wordmark + Desfazer + Refazer + Salvar + Publicar + Despublicar `icon` + Historico `outlined` + botao de tema) so caber sem overflow a partir de ~794px, medido com a fonte real do app (`test/support/app_fonts.dart`) nos tres estados de publicacao (`No ar`, `Fora do ar`, `Alteracoes nao publicadas`; convergem porque o indicador de status e `Flexible` com ellipsis, e nao entra mais nessa conta). 760px e 794px eram incompativeis: ou o rotulo cabia, ou o limiar ficava em 760.
>
> (Uma primeira rodada desta decisao, com um preview que rotulava `Despublicar` tambem, mediu ~890px e o dono decidiu em cima desse numero errado; a segunda rodada corrigiu o preview para rotular so `Historico` — como T1.1 sempre pediu — e recalibrou pela medicao certa, ~794px. O numero final abaixo e o corrigido.)
>
> O dono escolheu manter o rotulo em `Historico` (T1.1 vence) e aceitar que o limiar suba. Razao dada: `Despublicar` e acao rara e destrutiva, `Historico` e a que se procura — so esta ganha rotulo. `AppSizes.topBarActionsFitWidth` passou a `840` (794px de cruzamento + 46px de folga, a mesma margem ja usada nas calibracoes anteriores, documentada no dartdoc da constante).
>
> **Custo aceito:** quem estiver com a janela entre 760px e 840px passa a ver a barra colapsada no overflow unico do shell (o mesmo widget generico, sem menu novo) — antes, essa faixa mostrava a barra cheia.

**DoD T1:** desktop tem Historico e Despublicar sem menu especifico; compacto (abaixo de `AppSizes.topBarActionsFitWidth`, hoje 840px) mantem Salvar direto e as demais acoes acessiveis por overflow unico; despublicar nao apaga versoes; widgets cobrem quatro estados e duas larguras.

### T2 - Buscar versao somente quando solicitada [paralela a T1]

**Precedencia:** T0.

1. Criar entidade/model zard `LoadedContentVersion`, `GetContentVersionUseCase` e `getVersion` no repositorio real/fake, usando o GET existente.
2. Criar `VersionReviewCubit` escopado a revisao. Ele nao escreve em `EditorCubit` nem reconstrói o canvas principal.
3. Cobrir sucesso, 404, rede e JSON invalido em data/domain/cubit.

**DoD T2:** a lista nao baixa specs em massa; escolher versao faz uma requisicao de detalhe; falha preserva editor; fake e rede real produzem o mesmo tipo; testes de camada passam.

### T3 - Ver antes de alterar

**Precedencia:** T2.

1. Cada linha passa a oferecer `Ver`, `Comparar` e `Carregar no rascunho`; `Ver` e primario e selecionar linha nao e destrutivo.
2. Criar `VersionReviewDialog` amplo no desktop, com metadados e `SduiView` historico dentro de `AbsorbPointer` e `FocusScope(canRequestFocus: false)`; no compacto ele ocupa a tela, sem esmagar preview.
3. `Carregar no rascunho` aplica o `ContentSpec` ja lido por `_emitDocument`, empilha undo e fica somente em memoria. Ele nunca chama o endpoint `restore`; o proximo `Salvar` persiste o novo draft.
4. Renovar a confirmacao local conforme os textos acima. Se o editor estiver dirty, somente descartar ou cancelar sao permitidos.

**DoD T3:** ver vN nao faz `PUT`/`POST`, nao deixa editor dirty e nao muda ponteiro; toque, Tab e digitacao nao interagem com o snapshot; carregar nao chama restore, fica dirty e pode ser desfeito; erro nao fecha historico/canvas; widget tests cobrem sucesso e falhas.

### T4 - Motor puro de comparacao SDUI

**Precedencia:** T2. Vive em `packages/sdui_core`, sem Flutter, Dio ou Bloc.

1. Criar `compareContentSpecs(base, candidate)` deterministico por ID, com propriedades e eventos iguais/alterados, tipo alterado, nos exclusivos, `safeArea` e metadados do `ContentSpec`.
2. Criar `copyComparableNodeProperties(base, candidate, nodeId)`: mesmo ID/tipo sao precondicoes; retorna novo `ContentSpec` e erro tipado se nao puder copiar.
3. Cobrir raiz nula, no unico, diferenca de raiz, IDs duplicados, propriedades JSON aninhadas, eventos, `safeArea` e metadados. ID duplicado bloqueia comparacao inteira e nenhuma operacao pode alterar no algum. Ordem de filhos e reportada, nunca aplicada nesta fase.
4. Exportar no barrel e documentar semantica de IDs para componentes, acoes e binding.

**DoD T4:** testes cobrem diferencas e precondicoes; ID duplicado devolve erro tipado e deixa ambos os specs intactos; copia nao muta entrada, nao duplica ID e preserva estrutura; `dart test packages/sdui_core` e `flutter analyze` verdes.

### T5 - Comparar e recuperar propriedades com seguranca

**Precedencia:** T3 e T4.

1. `Comparar` abre base a esquerda e candidata a direita. A base default e o rascunho; quando houver, o usuario pode trocar para a versao no ar. No compacto, usar abas ou controle segmentado, nunca duas colunas comprimidas.
2. Preview e arvore exibem os mesmos marcadores: `Propriedades alteradas`, `Eventos alterados`, `Safe area alterada`, `Metadados alterados`, `Somente no rascunho`, `Somente na versao` e `Tipo mudou`, todos com icone + texto + cor. Eventos, safe area e metadados declaram que sao somente leitura nesta v1.
3. A seta para a esquerda aparece apenas em propriedades de no compativel. Ela chama o motor puro, atualiza `EditorCubit`, empilha undo e marca dirty; nao salva nem chama restore.
4. Para estrutura, tipo, eventos, safe area ou metadados, explicar ausencia da seta e oferecer somente `Carregar versao inteira no rascunho` como alternativa segura. Com ID duplicado, bloquear a comparacao inteira e indicar que a versao nao pode ser comparada com seguranca.
5. Reexecutar diagnosticos apos copia; se criar erro, mostra-lo no fluxo normal de publicacao, sem desfazer a acao escondido.

**DoD T5:** comparar e puro; seta so existe em ID/tipo compativeis; copia somente propriedades e Ctrl+Z a desfaz; eventos, safe area e metadados nunca aparecem como iguais por omissao; IDs duplicados nao exibem seta nem mutam o documento; preview/arvore/Inspector refletem rascunho; mobile nao corta texto; widget/golden tests cobrem marcadores e layouts.

### T6 - Provar o ciclo imutavel e atualizar docs

**Precedencia:** T1, T3 e T5.

1. Provar `Ver v2 -> Comparar -> copiar ou carregar -> Salvar -> Publicar`. Save toca apenas draft. Publish consulta a versao atualmente publicada e e no-op se os JSONB forem semanticamente iguais; se o draft diferir, cria vN+1, inclusive quando ele coincidir com uma versao antiga que nao e a versao no ar.
2. Implementar essa idempotencia dentro de uma unica transacao de publish: ler `draftSpec`, `publishedVersionId`, `publishedAt` e o snapshot publicado somente por `tx`; comparar igualdade JSONB sem interpretar o schema SDUI. No no-op, atualizar `draftUpdatedAt` para o `publishedAt` existente, devolver `hasUnpublishedChanges: false` e nao tocar `publishedAt`, `publishedVersionId` ou `ContentVersion`. Assim a proxima leitura continua limpa e o ETag publico permanece estavel.
3. Garantir que ver, comparar, carregar localmente, cancelar e fechar nao criam `ContentVersion`. O endpoint remoto restore continua fora da UI deste fluxo.
4. Criar doc viva em `docs/50-historico-seguro/` quando a execucao iniciar e atualizar CHANGELOG, roadmap e relatorio final ao concluir.

**DoD T6:** API prova que acoes puras nao mudam contagem; carregar nao chama restore nem publica; `carregar -> Ctrl+Z -> publicar` publica exatamente o spec que a tela mostra; publicar JSONB igual ao que esta no ar nao cria versao, conserva `publishedAt`/ETag e torna `hasUnpublishedChanges` falso mesmo apos novo GET; publicar versao antiga diferente cria exatamente uma nova e preserva anteriores; despublicar conserva `latestVersion`; docs registram concorrencia e ausencia de historico de autosaves.

### T7 - E2E humano em homologacao

**Precedencia:** T1-T6 implantadas em hml. Bateria automatizada fica depois desta fase, conforme regra do repositorio.

1. Criar `docs/50-historico-seguro/e2e_hml.sh`, `e2e_shots.sh` e `e2e_drive.mjs`, no padrao do item 24. Os scripts usam somente hml, fixture com slug exclusivo, `mktemp -d`, Chrome CDP e `trap EXIT` para remover conteudo/projeto/perfil.
2. O contrato API prepara v1, v2 e draft divergente; prova leitura pura, carregar local, idempotencia JSONB, ownership 404 e `carregar -> Ctrl+Z -> publicar`. O driver visual captura desktop, overflow compacto, ver, comparar, seta, cancelar carregar, carregar e publicar.
3. Apos passos destrutivos, conferir por API contagem, ponteiros e marcador do spec; apos passos puros, provar que nada mudou. Provocar falha do GET de detalhe por CDP e capturar estado distinto.
4. O dev humano revisa os prints, inclusive direcao inequívoca da seta e distincao de superficie somente leitura.

**DoD T7:** ambos os scripts hml auto-limpantes passam duas vezes; acoes puras conservam banco; carregar local, undo e publicacao tem spec/contagem exatos; prints desktop/compacto, sucesso e falha do detalhe sao aprovados pelo humano.

### T8 - Bateria e encerramento

**Precedencia:** T7 aprovada.

1. Completar specs backend para posse, detalhe e append-only; manter testes do kernel como contrato de regressao.
2. Cobrir modelo, repositorios, use case, cubits, confirmacoes, overflow, revisao, comparacao e undo posterior a seta.
3. Rodar cancelas e anexar evidencias/relatorio final.

**DoD T8:** `pnpm build`, `pnpm lint`, testes backend, `flutter analyze`, testes do editor e `dart test packages/sdui_core` verdes; E2E e prints anexados; nenhum fake de producao, TODO ou endpoint do recorte permanece sem cobertura.

## Dependencias e paralelismo

```text
T0
|- T1 acoes visiveis -----------------+
`- T2 leitura -> T3 ver -------------+-> T6 -> T7 E2E -> T8 bateria
                `-> T4 kernel -> T5 -+
```

T1 e T2 podem ser PRs paralelas. T3 e T4 podem avancar em paralelo depois de T2. T5 integra os dois ramos. Uma fase corresponde a uma PR; desvio de escopo requer aprovacao e registro, nao alteracao silenciosa deste plano.

## Arquivos previstos

| Area | Arquivos principais |
| --- | --- |
| Backend | Nenhuma tabela ou rota nova; `publish()` ganha igualdade JSONB contra a versao no ar e specs de ownership/idempotencia. |
| Data/domain | Entidade versionada, modelos zard, repositorios real/fake e use cases. |
| Presentation | Historico, linha, revisao, confirmacoes, `editor_top_registrar` e testes. |
| Kernel | Modulo de diff/copia em `packages/sdui_core/lib/src/ops/`, export e testes. |
| Docs/E2E | `docs/50-historico-seguro/`, roteiro hml/CDP, evidencias, CHANGELOG e relatorio final. |

## Riscos controlados

| Risco | Protecao |
| --- | --- |
| Ler versao sobrescreve trabalho | `Ver` usa GET e cubit isolado; `Carregar` e local ate Salvar. |
| Merge sem contrato quebra arvore | v1 copia somente propriedades de ID/tipo iguais. |
| IDs duplicados | motor nao cria/remove/realoca nos; testes exigem isso. |
| Snapshot parece editavel | `AbsorbPointer`, foco bloqueado e teste de toque/Tab/digitacao. |
| Acoes somem no compacto | teste do overflow unico abaixo de `AppSizes.topBarActionsFitWidth` (840px), com casos em 640px e 830px. |
| Confundir draft/publicado | versao, icone e texto em toda superficie; publicar e unico comando que move ponteiro. |
| Regressao no app cliente | contrato publico e `driva_client` ficam fora; E2E confere API privada. |

## Fora de escopo

- Historico de autosave, ator e eventos de dominio; depende de auth/auditoria.
- Merge estrutural: inserir, remover, trocar tipo e movimento; exige discovery e contrato proprio de patch/conflito.
- Comparar duas versoes antigas arbitrarias, diff textual JSON, comentarios por versao, agendamento e aprovacao.
- Mudanca no contrato publico ou no app cliente.

## Definition of Done do plano completo

- [ ] Todas as tarefas T0-T8 satisfazem suas DoDs e deixam evidencia.
- [ ] Ver versao nao altera draft, ponteiro, historico ou contagem.
- [ ] Comparar e seta obedecem a compatibilidade, ficam desfaziveis e nao salvam automaticamente.
- [ ] Carregar e publicar depois preserva versoes e cria versao nova apenas quando o JSONB difere do que esta no ar; nunca move ponteiro retroativamente.
- [ ] Quatro estados e acoes funcionam em desktop/compacto, com texto e icone.
- [ ] Cancelas locais verdes e E2E hml auto-limpante passa duas vezes, com prints aprovados pelo humano.
- [ ] Agente fiscalizador independente revisou plano, codigo e evidencias e registrou `IMPRESSED` sem achado bloqueante aberto.

## Referencias

- [Roadmap item 50](../../roadmap.md)
- [Plano do item 24](../24-publicacao-versionamento/plan.md)
- [Relatorio final do item 24](../../24-publicacao-versionamento/final_report.md)
- [Referencia Squidex](../../referencias/squidex-history/README.md)
