import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:flutter/material.dart';

/// A faixa em que o painel direito (Inspector) colapsado se transforma (D2).
/// Sem abas — um único controle de reabrir.
class RightPanelRail extends StatelessWidget {
  const RightPanelRail({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EditorLayoutScope.of(context)!;
    return PanelRail(
      items: [
        PanelRailButton(
          icon: Icons.tune,
          label: 'Inspector',
          onPressed: controller.expandRightPanel,
        ),
      ],
    );
  }
}
