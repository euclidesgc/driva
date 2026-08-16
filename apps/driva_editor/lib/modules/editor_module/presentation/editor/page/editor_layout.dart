import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:equatable/equatable.dart';

enum LeftPanelTab { widgets, tree }

class EditorLayout extends Equatable {
  const EditorLayout({
    this.leftPanelWidth = AppSizes.workspacePanelDefaultLeftWidth,
    this.rightPanelWidth = AppSizes.workspacePanelDefaultRightWidth,
    this.leftPanelCollapsed = false,
    this.rightPanelCollapsed = false,
    this.leftPanelTab = LeftPanelTab.widgets,
  });

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
