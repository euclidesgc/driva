import 'dart:async';

import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart'
    as domain;
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:flutter/foundation.dart';

/// Fica fora do `EditorCubit` de propósito (D8): o cubit `emit` é o caminho
/// quente do editor, e colapso de painel não tem por que passar por ele.
class EditorLayoutController extends ValueNotifier<EditorLayout> {
  EditorLayoutController({
    EditorLayout initial = const EditorLayout(),
    this.getLayoutUseCase,
    this.saveLayoutUseCase,
  }) : super(initial) {
    collapsedPaletteCategories.addListener(_scheduleSave);
    collapsedInspectorSections.addListener(_scheduleSave);
    // `null` (D19: sem DI, ex. `editor_perf_test.dart`) resolve na hora — sem
    // isso, `EditorPage` esperaria por um boot que nunca vai rodar.
    ready = getLayoutUseCase == null ? SynchronousFuture<void>(null) : _boot();
  }

  /// `null` = controller só em memória, sem persistência (D19) — mesmo
  /// cenário de quem monta `EditorPage` sem passar pelo `pageBuilder`.
  final GetEditorLayoutUseCase? getLayoutUseCase;
  final SaveEditorLayoutUseCase? saveLayoutUseCase;

  /// Completa quando o boot (F6) termina — layout carregado e reclampado
  /// (D13), ou dobrado ao padrão (D12). `EditorPage` aguarda antes de montar
  /// `EditorWorkspace`, para o `ResizableSplitView` nascer já com a largura
  /// certa, em vez de precisar reagir a uma mudança pós-montagem.
  late final Future<void> ready;

  /// Grupos colapsados da paleta (F4b), migrados aqui pela F5 (D28): um
  /// notifier irmão, não um campo de [EditorLayout], para que o
  /// `ValueListenableBuilder` que o lê continue escopado só à lista de
  /// grupos — nunca ao painel inteiro (D8›R5, um andar abaixo) — e para não
  /// herdar a igualdade por referência de `Set` dentro do `Equatable` de
  /// [EditorLayout].
  final ValueNotifier<Set<String>> collapsedPaletteCategories = ValueNotifier(
    {},
  );

  /// Mesmo papel de [collapsedPaletteCategories], para as seções do
  /// Inspector (F6): chave é o rótulo do grupo, lembrado globalmente entre
  /// nós selecionados (Q2/P3), não por tipo de nó.
  final ValueNotifier<Set<String>> collapsedInspectorSections = ValueNotifier(
    {},
  );

  /// Modo tela cheia (F7/D15). Notifier irmão, fora de [EditorLayout] de
  /// propósito: ao contrário de largura/colapso/aba, tela cheia não é hábito
  /// de trabalho — é um momento da sessão — e por isso nunca passa por
  /// [_snapshotNow]/[_applySnapshot] (a ida e volta com o disco).
  final ValueNotifier<bool> isFullscreen = ValueNotifier(false);

  void enterFullscreen() => isFullscreen.value = true;

  void exitFullscreen() => isFullscreen.value = false;

  void toggleFullscreen() => isFullscreen.value = !isFullscreen.value;

  Timer? _saveTimer;
  bool _isBooting = false;
  bool _disposed = false;

  static const _saveDebounce = Duration(milliseconds: 400);

  void collapseLeftPanel() => _update(leftPanelCollapsed: true);

  void expandLeftPanel() => _update(leftPanelCollapsed: false);

  void collapseRightPanel() => _update(rightPanelCollapsed: true);

  void expandRightPanel() => _update(rightPanelCollapsed: false);

  void setLeftPanelTab(LeftPanelTab tab) => _update(leftPanelTab: tab);

  /// Largura já chega clampada — quem chama é o `ResizeHandle` via
  /// `ResizableSplitView`, que já aplica `minPanelWidth`/`maxPanelWidth`.
  void setLeftPanelWidth(double width) => _update(leftPanelWidth: width);

  void setRightPanelWidth(double width) => _update(rightPanelWidth: width);

  /// Reabre o painel esquerdo já na aba pedida — a faixa fina é atalho, não só
  /// interruptor (D2, aceite 26): clicar no ícone Árvore com a paleta
  /// colapsada tem de resultar na aba Árvore visível, não na última aba
  /// lembrada.
  void showLeftPanelTab(LeftPanelTab tab) =>
      _update(leftPanelCollapsed: false, leftPanelTab: tab);

  void _update({
    double? leftPanelWidth,
    double? rightPanelWidth,
    bool? leftPanelCollapsed,
    bool? rightPanelCollapsed,
    LeftPanelTab? leftPanelTab,
  }) {
    value = value.copyWith(
      leftPanelWidth: leftPanelWidth,
      rightPanelWidth: rightPanelWidth,
      leftPanelCollapsed: leftPanelCollapsed,
      rightPanelCollapsed: rightPanelCollapsed,
      leftPanelTab: leftPanelTab,
    );
    _scheduleSave();
  }

  Future<void> _boot() async {
    _isBooting = true;
    // `finally` é o que garante que um boot que lança (ex.: `TypeError` de
    // cast num JSON salvo com tipo errado, que escapa do `on Exception
    // catch` do repositório) não deixe `_isBooting` travado em `true` para
    // sempre — sem isto, `_scheduleSave` nunca mais gravaria nada na sessão.
    try {
      final result = await getLayoutUseCase!();
      if (_disposed) return;
      result.fold((_) {}, _applySnapshot);
    } finally {
      _isBooting = false;
    }
  }

  void _applySnapshot(domain.EditorLayoutSnapshot snapshot) {
    value = EditorLayout(
      leftPanelWidth: _clampPanelWidth(snapshot.leftPanelWidth),
      rightPanelWidth: _clampPanelWidth(snapshot.rightPanelWidth),
      leftPanelCollapsed: snapshot.leftPanelCollapsed,
      rightPanelCollapsed: snapshot.rightPanelCollapsed,
      leftPanelTab: switch (snapshot.leftPanelTab) {
        domain.EditorLeftPanelTab.widgets => LeftPanelTab.widgets,
        domain.EditorLeftPanelTab.tree => LeftPanelTab.tree,
      },
    );
    collapsedPaletteCategories.value = snapshot.collapsedPaletteGroups;
    collapsedInspectorSections.value = snapshot.collapsedInspectorSections;
  }

  // D13: o reclamp contra a janela atual já é responsabilidade contínua do
  // `ResizableSplitView` (o piso dinâmico de D14, recalculado a cada frame);
  // este clamp cobre só o teto/piso fixos que o valor salvo em disco pode
  // violar (ex.: uma versão anterior gravou fora do intervalo hoje válido).
  double _clampPanelWidth(double width) => width.clamp(
    AppSizes.workspacePanelMinWidth,
    AppSizes.workspacePanelMaxWidth,
  );

  void _scheduleSave() {
    final useCase = saveLayoutUseCase;
    // O boot reaplica o valor recém-lido do disco: sem esta guarda, o
    // próprio carregamento agendaria uma gravação de volta, idêntica e
    // inútil.
    if (useCase == null || _isBooting) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(_flush(useCase)));
  }

  Future<void> _flush(SaveEditorLayoutUseCase useCase) {
    return useCase(_snapshotNow());
  }

  domain.EditorLayoutSnapshot _snapshotNow() => domain.EditorLayoutSnapshot(
    leftPanelWidth: value.leftPanelWidth,
    rightPanelWidth: value.rightPanelWidth,
    leftPanelCollapsed: value.leftPanelCollapsed,
    rightPanelCollapsed: value.rightPanelCollapsed,
    leftPanelTab: switch (value.leftPanelTab) {
      LeftPanelTab.widgets => domain.EditorLeftPanelTab.widgets,
      LeftPanelTab.tree => domain.EditorLeftPanelTab.tree,
    },
    collapsedPaletteGroups: collapsedPaletteCategories.value,
    collapsedInspectorSections: collapsedInspectorSections.value,
  );

  @override
  void dispose() {
    _disposed = true;
    final pendingSave = _saveTimer;
    final useCase = saveLayoutUseCase;
    // Uma troca de painel um instante antes de sair da tela (aceite 29) não
    // pode se perder: havendo gravação agendada, ela dispara aqui — na hora,
    // sem esperar o debounce que não vai mais rodar.
    if (pendingSave != null && pendingSave.isActive && useCase != null) {
      unawaited(_flush(useCase));
    }
    pendingSave?.cancel();
    collapsedPaletteCategories
      ..removeListener(_scheduleSave)
      ..dispose();
    collapsedInspectorSections
      ..removeListener(_scheduleSave)
      ..dispose();
    isFullscreen.dispose();
    super.dispose();
  }
}
