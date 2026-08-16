import 'package:equatable/equatable.dart';

enum EditorLeftPanelTab { widgets, tree }

/// O que a F6 persiste: a foto do layout do editor entre sessões (D11).
///
/// Nome deliberadamente distinto do `EditorLayout` de
/// `presentation/editor/page/editor_layout.dart` (o estado em memória da F5)
/// — os dois vão conviver no mesmo arquivo na fase 3, e `EditorLayoutSnapshot`
/// evita a colisão de identificador sem exigir prefixo de biblioteca.
///
/// Larguras e conjuntos aqui são o valor **bruto** salvo, sem reclamp (D13) —
/// quem restaura decide os limites da janela atual.
class EditorLayoutSnapshot extends Equatable {
  const EditorLayoutSnapshot({
    this.leftPanelWidth = defaultLeftPanelWidth,
    this.rightPanelWidth = defaultRightPanelWidth,
    this.leftPanelCollapsed = false,
    this.rightPanelCollapsed = false,
    this.leftPanelTab = EditorLeftPanelTab.widgets,
    this.collapsedPaletteGroups = const {},
    this.collapsedInspectorSections = const {},
  });

  /// Espelha `ResizableSplitView.initialLeftWidth`/`initialRightWidth`
  /// (`core/widgets/layout/`). Duplicado, não importado: domain é Dart puro e
  /// não depende de `core/theme`/`core/widgets`. Aceite 31 do plano é a fonte
  /// da verdade caso os dois valores um dia divirjam.
  static const double defaultLeftPanelWidth = 280;
  static const double defaultRightPanelWidth = 320;

  final double leftPanelWidth;
  final double rightPanelWidth;
  final bool leftPanelCollapsed;
  final bool rightPanelCollapsed;
  final EditorLeftPanelTab leftPanelTab;
  final Set<String> collapsedPaletteGroups;

  /// Chave é o rótulo do grupo (`PropSection.label`), não o tipo de nó —
  /// lembrança global entre nós, decisão Q2/P3.
  final Set<String> collapsedInspectorSections;

  EditorLayoutSnapshot copyWith({
    double? leftPanelWidth,
    double? rightPanelWidth,
    bool? leftPanelCollapsed,
    bool? rightPanelCollapsed,
    EditorLeftPanelTab? leftPanelTab,
    Set<String>? collapsedPaletteGroups,
    Set<String>? collapsedInspectorSections,
  }) {
    return EditorLayoutSnapshot(
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      leftPanelCollapsed: leftPanelCollapsed ?? this.leftPanelCollapsed,
      rightPanelCollapsed: rightPanelCollapsed ?? this.rightPanelCollapsed,
      leftPanelTab: leftPanelTab ?? this.leftPanelTab,
      collapsedPaletteGroups:
          collapsedPaletteGroups ?? this.collapsedPaletteGroups,
      collapsedInspectorSections:
          collapsedInspectorSections ?? this.collapsedInspectorSections,
    );
  }

  @override
  List<Object?> get props => [
    leftPanelWidth,
    rightPanelWidth,
    leftPanelCollapsed,
    rightPanelCollapsed,
    leftPanelTab,
    collapsedPaletteGroups,
    collapsedInspectorSections,
  ];
}
