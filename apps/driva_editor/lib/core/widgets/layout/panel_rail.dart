import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:flutter/material.dart';

/// A faixa fina em que um painel colapsado do editor se transforma (D2): não
/// some, vira uma coluna de ícones — cada um o controle de reabrir o painel
/// naquela aba específica.
class PanelRail extends StatelessWidget {
  const PanelRail({required this.items, super.key});

  final List<PanelRailButton> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return SizedBox(
      width: AppSizes.panelRailWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border(right: BorderSide(color: colors.border)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s4),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}
