# PRD — Módulo Página (I1)

> Aprovado pelo dev em 2026-07-01 (aprovação do plano da sessão de retomada). Dono: PM. "Pronto" = bater com este documento.

## Resultado esperado

Um usuário abre o editor no Chrome, cria a página "Home", arrasta primitivos da paleta, os reordena na árvore, edita propriedades no inspector vendo o preview refletir imediatamente na moldura de dispositivo, salva com Ctrl+S, recarrega o browser, reabre a página e encontra tudo como deixou — persistido no Postgres.

## Caminho feliz

1. Lista de páginas carrega (`GET /v1/pages`) → grid de cards.
2. "Nova página" → nome + tela de destino → `POST /v1/pages` → abre o editor.
3. Editor carrega o spec (`GET /v1/pages/:id`) → 4 painéis renderizam.
4. Arrastar primitivo da paleta → bloco entra na árvore com defaults do catálogo → preview atualiza.
5. Selecionar bloco (na árvore ou no preview) → inspector mostra o form derivado do descriptor.
6. Editar prop → preview reflete no mesmo frame; estado vira "não salvo".
7. Ctrl+S / botão Salvar → `PUT /v1/pages/:id` → indicador "salvo".

## Exceções e casos de borda

| Caso | Comportamento |
|---|---|
| Backend fora do ar | `NetworkFailure` → mensagem clara + ação de tentar de novo; editor não perde o documento em memória |
| Página inexistente (`/pages/x/edit`) | `NotFoundFailure` → tela de erro tratada, link de volta à lista |
| Spec inválido vindo do backend | `ValidationFailure` (via `parsePageSpec`) → erro descritivo, sem crash |
| id malformado na URL | fallback de rota (tryParse/validação), sem crash |
| Página vazia (root sem filhos) | estado vazio com orientação ("arraste um widget") |
| Remover bloco selecionado | seleção limpa; inspector volta ao estado da página |
| Mover bloco para a própria subárvore | operação ignorada (guarda no kernel) |
| Salvar falha | indicador "falha ao salvar" + retry; documento intacto |
| Fechar/recarregar com alterações não salvas | I1 aceita perda (sem auto-save); indicador de "não salvo" sempre visível |

## Analytics

Nenhum evento no I1 (registrar explicitamente em ANALYTICS.md).

## Erros monitorados

As 4 redes globais (`bootstrap.dart`) logam erros imprevistos; `Failure` tipadas cobrem os previstos. ERROR_LOGS.md documenta ambos por módulo.

## Testes que cada etapa pede

- **Kernel**: parse/validação (fixtures válidas e inválidas), tree_ops, catálogo (fase 1 — feito).
- **Renderer**: contrato catálogo↔registry, fixture ponta a ponta, props→estilo, ações, nodeWrapper (fase 2 — feito).
- **Editor**: bloc_test dos cubits (lista e editor: cada mutação + save), widget tests por estado, golden dos painéis — **por último** (fase 6).
- **E2E manual**: roteiro no test_plan.md; quem testa é o dev.

## Critérios de aceite

1. Roteiro do caminho feliz completo sem erro no console.
2. Todos os 14 primitivos arrastáveis e editáveis.
3. Preview fiel (mesmo renderer) com 3 presets de dispositivo + zoom.
4. UX no padrão do protótipo (layout 3 colunas + canvas, painéis redimensionáveis, seleção com contorno + label).
5. Acessibilidade: navegação por teclado na árvore, tooltips, cor nunca como único sinal.
6. `flutter analyze` verde; baterias de teste verdes; docs vivas em dia (DoD).
