# Variance report — Ergonomia do editor (item 41)

Desvios pontuais encontrados pelo QA na revisão da F6 (layout persistido) contra
`docs/17-ergonomia-editor/plan.md`. Registro técnico, não é apêndice de
desculpas — é para quem tocar essas partes depois saber o que foi decisão e o
que ficou em aberto.

## VR-17-01 — `domain/entities/editor_layout.dart` virou `editor_layout_snapshot.dart`

**O plano diz:** F6, lista de arquivos — `domain/entities/editor_layout.dart`.

**O que foi feito:** a entidade nasceu como `EditorLayoutSnapshot`, no arquivo
`editor_layout_snapshot.dart`.

**Por quê:** colisão de identificador com o `EditorLayout` que já existe em
`presentation/editor/page/editor_layout.dart` (o estado em memória, da F5). Os
dois convivem — um é o valor bruto persistido (domain), o outro é o estado que
o `ValueNotifier` do editor carrega (presentation) — e `EditorLayoutSnapshot`
evita a colisão sem exigir prefixo de biblioteca.

**Efeito:** só de nome. Sem mudança de comportamento nem de contrato.

## VR-17-02 — 7 arquivos fora da lista de arquivos da F6 foram tocados

**O plano diz:** F6, lista de arquivos — `domain/entities/editor_layout.dart`,
`domain/repositories/editor_layout_repository.dart`,
`domain/use_cases/get_editor_layout_use_case.dart` +
`save_editor_layout_use_case.dart`, `data/models/editor_layout_model.dart`,
`data/repositories/editor_layout_repository_impl.dart`,
`editor_injection.dart`, `editor_page.dart`, `editor_layout_controller.dart`,
`.../inspector/prop_section.dart`.

**O que foi feito, além dessa lista:**
`core/widgets/layout/resizable_split_view.dart`, `core/theme/app_sizes.dart`,
`presentation/editor/page/editor_layout.dart`,
`presentation/editor/page/editor_workspace.dart`,
`presentation/editor/widgets/inspector/inspector_area.dart`,
`presentation/editor/widgets/inspector/inspector_panel.dart`,
`presentation/editor/widgets/inspector/inspector_prop_list.dart`.

**Por quê:** plumbing necessário para os callbacks de largura
(`onLeftWidthChanged`/`onRightWidthChanged`) e o repasse de
`collapsedInspectorSections` chegarem do `EditorLayoutController` até onde o
`ResizableSplitView` e o `InspectorPropList` precisam deles — nenhum desses
sete arquivos estava pronto para receber os dois. Dois deles
(`resizable_split_view.dart`, `app_sizes.dart`) são tier `core/` compartilhado,
não exclusivos do `editor_module`.

**Efeito:** nenhum desvio de contrato ou de comportamento — é a fiação que o
plano descreveu em prosa ("gravação com debounce", "reclamp na restauração")
sem listar todo arquivo intermediário.

## VR-17-03 — `CHANGELOG.md` `Unreleased` não atualizado por nenhuma fase do item 41

Nenhuma das fases F1 a F6 do item 41 (ergonomia do editor) atualizou a seção
`Unreleased` do `CHANGELOG.md`, apesar da regra do `CLAUDE.md` ("a seção
`Unreleased` é atualizada no mesmo PR da mudança"). É dívida acumulada da
feature inteira, não desta fase isolada — fica registrada aqui para fechar no
wrap final (F9), não fase a fase.

## VR-17-04 — Schema de `EditorLayoutModel` sem campos opcionais: adicionar um campo no futuro quebra layouts salvos

**O que existe:** `EditorLayoutModel._schema` (zard) exige as 7 chaves atuais
(`leftPanelWidth`, `rightPanelWidth`, `leftPanelCollapsed`,
`rightPanelCollapsed`, `leftPanelTab`, `collapsedPaletteGroups`,
`collapsedInspectorSections`) — nenhuma é opcional.

**Consequência:** se uma fase futura acrescentar um campo ao layout
persistido (ex.: um quarto painel, um novo modo), todo layout já salvo por
usuários antigos no `localStorage` passa a falhar `safeParse` (chave nova
ausente) e cai em `Left`. Pelo D12 (`EditorLayoutController._boot`, `result.fold((_) {}, _applySnapshot)`), isso é absorvido como corrupção comum —
dobra pro padrão em silêncio, sem erro visível. Não quebra a aplicação, mas o
usuário perde silenciosamente toda a config de layout salva (larguras,
colapsos, seções do Inspector).

**Status:** decisão implícita, não tomada explicitamente por ninguém — é
consequência do schema atual, não uma escolha registrada em nenhum D do plano.
Registrado aqui para quem tocar o schema depois decidir se quer migração
versionada, campos opcionais com default, ou aceitar o dobro-ao-padrão como
comportamento pretendido também para esse caso.
