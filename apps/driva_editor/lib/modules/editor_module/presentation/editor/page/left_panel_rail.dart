import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:flutter/material.dart';

/// A faixa em que o painel esquerdo colapsado se transforma (D2). Cada botão
/// é atalho, não só interruptor (aceite 26): reabre o painel já na aba
/// correspondente via `showLeftPanelTab`, nunca na última aba lembrada.
class LeftPanelRail extends StatelessWidget {
  const LeftPanelRail({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EditorLayoutScope.of(context)!;
    return PanelRail(
      items: [
        PanelRailButton(
          icon: Icons.widgets_outlined,
          label: 'Widgets',
          onPressed: () => controller.showLeftPanelTab(LeftPanelTab.widgets),
        ),
        PanelRailButton(
          icon: Icons.account_tree_outlined,
          label: 'Árvore',
          onPressed: () => controller.showLeftPanelTab(LeftPanelTab.tree),
        ),
      ],
    );
  }
}
