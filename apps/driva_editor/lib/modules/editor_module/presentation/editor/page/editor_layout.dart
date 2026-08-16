import 'package:equatable/equatable.dart';

enum LeftPanelTab { widgets, tree }

class EditorLayout extends Equatable {
  const EditorLayout({
    this.leftPanelWidth = defaultLeftPanelWidth,
    this.rightPanelWidth = defaultRightPanelWidth,
    this.leftPanelCollapsed = false,
    this.rightPanelCollapsed = false,
    this.leftPanelTab = LeftPanelTab.widgets,
  });

  /// Espelha `ResizableSplitView.initialLeftWidth`/`initialRightWidth`
  /// (`core/widgets/layout/`) e `EditorLayoutSnapshot.defaultLeftPanelWidth`/
  /// `defaultRightPanelWidth` (domain) — duplicado nas três camadas de
  /// propósito, cada uma sem depender da outra.
  static const double defaultLeftPanelWidth = 280;
  static const double defaultRightPanelWidth = 320;

  final double leftPanelWidth;
  final double rightPanelWidth;
  final bool leftPanelCollapsed;
  final bool rightPanelCollapsed;
  final LeftPanelTab leftPanelTab;

  EditorLayout copyWith({
    double? leftPanelWidth,
    double? rightPanelWidth,
    bool? leftPanelCollapsed,
    bool? rightPanelCollapsed,
    LeftPanelTab? leftPanelTab,
  }) {
    return EditorLayout(
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      leftPanelCollapsed: leftPanelCollapsed ?? this.leftPanelCollapsed,
      rightPanelCollapsed: rightPanelCollapsed ?? this.rightPanelCollapsed,
      leftPanelTab: leftPanelTab ?? this.leftPanelTab,
    );
  }

  @override
  List<Object?> get props => [
    leftPanelWidth,
    rightPanelWidth,
    leftPanelCollapsed,
    rightPanelCollapsed,
    leftPanelTab,
  ];
}
