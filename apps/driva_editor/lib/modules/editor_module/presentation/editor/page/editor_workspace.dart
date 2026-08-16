import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/layout/layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_shortcuts.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_top_registrar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel_rail.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/right_panel_rail.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/status_bar_area.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:sdui_flutter/sdui_flutter.dart';

class EditorWorkspace extends StatelessWidget {
  const EditorWorkspace({
    required this.projectFuture,
    required this.layoutController,
    this.imageUrlResolver,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;

  /// O soquete da D7: montado aqui, acima de tudo o que hoje monta o
  /// `ResizableSplitView`, para que a F7 (tela cheia) o alcance sem um sexto
  /// passageiro no repasse por construtor do `VR-16-02`.
  final EditorLayoutController layoutController;

  final SduiImageUrlResolver? imageUrlResolver;

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
                leftPanelRail: const LeftPanelRail(),
                center: CenterArea(imageUrlResolver: imageUrlResolver),
                right: ColoredBox(
                  color: colors.panel,
                  child: const InspectorArea(),
                ),
                rightPanelRail: const RightPanelRail(),
              ),
            ),
            const StatusBarArea(),
          ],
        ),
      ),
    );

    return EditorLayoutScope(
      controller: layoutController,
      child: EditorTopRegistrar(
        projectFuture: projectFuture,
        child: workspace,
      ),
    );
  }
}
