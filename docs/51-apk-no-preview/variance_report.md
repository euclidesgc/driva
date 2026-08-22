# Variance report — item 51

## VR-51-01 — Fix de testabilidade em `canvas_area.dart`, fora do escopo declarado da T2.4

**Quando:** 2026-08-22, durante a execução da T2.4 (a bateria: da rota até o botão).

**O que o plano previa:** T2.4 tocaria exatamente dois arquivos, ambos de teste —
`editor_demo_apk_wiring_test.dart` (novo) e `preview_share_dialog_test.dart` (cresce).

**O que aconteceu:** ao escrever `editor_demo_apk_wiring_test.dart` — o teste que monta a árvore
real a partir da rota e clica em "Ver no celular", exigido pelo critério 1 do DoD da T2.4 —, o
especialista encontrou que `CanvasArea._openPreviewDialog`
(`apps/driva_editor/lib/modules/editor_module/presentation/editor/page/canvas_area.dart:131`)
monta a URL do preview com `Uri.base.origin`. `Uri.origin` lança `StateError` para qualquer
`scheme` que não seja `http`/`https`; sob `flutter test` (VM), `Uri.base` é sempre `file://...`.
Nenhum teste de widget, de ninguém, jamais teria conseguido clicar em "Ver no celular" pela
árvore real e chegar ao diálogo — o app trava ao computar a URL, antes mesmo de `showDialog`
rodar. É um bug de testabilidade **pré-existente**, herdado do item 41, que só ficou visível
porque esta foi a primeira vez que alguém escreveu esse teste específico.

**Correção aplicada** (8 linhas, no mesmo commit da T2.4):

```dart
final base = Uri.base;
final origin = base.scheme == 'http' || base.scheme == 'https'
    ? base.origin
    : base.toString();
final url = '$origin$location';
```

Fallback para `base.toString()` quando o scheme não é http/https, com comentário explicando a
restrição de plataforma (exceção documentada do CLAUDE.md — comenta o porquê, não o mecanismo).

**Por que isto é correção de erro, não mudança de exigência:** o DoD da T2.4 (critério 1) exige
que o teste monte a árvore a partir da rota e prove que a URL chega ao diálogo — sem o fix, isso
é **literalmente impossível de provar**, porque o `showDialog` nunca é alcançado no ambiente de
teste. Reverter o fix reverteria a própria prova que o item mais precisa (a defesa contra o R2 —
elo esquecido em silêncio), sem alternativa equivalente.

**Impacto em produção: nenhum.** Em Flutter Web real, `Uri.base.scheme` é sempre `http` ou
`https` — o branch novo (`base.toString()`) nunca executa fora de teste. Confirmado pela suíte
completa (`flutter test -r compact` — 763 testes, todos verdes) e por `flutter analyze`/
`gates_guard.sh` limpos.

**Aprovação:** dono, 2026-08-22, nesta sessão — "Aceitar e registrar".

**Sem afrouxar nada:** o DoD da T2.4 não mudou; o fix é aditivo e escopado a uma única linha de
lógica condicional, sem remover nem enfraquecer nenhuma verificação existente.
