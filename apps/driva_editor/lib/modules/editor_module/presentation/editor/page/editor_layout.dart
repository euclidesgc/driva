import 'package:equatable/equatable.dart';

enum LeftPanelTab { widgets, tree }

class EditorLayout extends Equatable {
  const EditorLayout({
    this.leftPanelCollapsed = false,
    this.rightPanelCollapsed = false,
    this.leftPanelTab = LeftPanelTab.widgets,
  });

  final bool leftPanelCollapsed;
  final bool rightPanelCollapsed;
  final LeftPanelTab leftPanelTab;

  EditorLayout copyWith({
    bool? leftPanelCollapsed,
    bool? rightPanelCollapsed,
    LeftPanelTab? leftPanelTab,
  }) {
    return EditorLayout(
      leftPanelCollapsed: leftPanelCollapsed ?? this.leftPanelCollapsed,
      rightPanelCollapsed: rightPanelCollapsed ?? this.rightPanelCollapsed,
      leftPanelTab: leftPanelTab ?? this.leftPanelTab,
    );
  }

  @override
  List<Object?> get props => [
    leftPanelCollapsed,
    rightPanelCollapsed,
    leftPanelTab,
  ];
}
