import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/layout/layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_shortcuts.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_top_registrar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/status_bar_area.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

class EditorWorkspace extends StatelessWidget {
  const EditorWorkspace({required this.projectFuture, super.key});

  final Future<Either<Failure, Project>> projectFuture;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;

    final workspace = EditorShortcuts(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ResizableSplitView(
                left: const LeftPanel(),
                center: const CenterArea(),
                right: ColoredBox(
                  color: colors.panel,
                  child: const InspectorArea(),
                ),
              ),
            ),
            const StatusBarArea(),
          ],
        ),
      ),
    );

    return EditorTopRegistrar(projectFuture: projectFuture, child: workspace);
  }
}
