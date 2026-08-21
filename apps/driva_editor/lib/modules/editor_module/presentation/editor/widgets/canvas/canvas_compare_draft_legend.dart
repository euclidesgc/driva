import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Conteúdo do lado esquerdo de `VersionCompareModeBar`: identifica o
/// rascunho na barra única do modo de comparação lado a lado.
class CanvasCompareDraftLegend extends StatelessWidget {
  const CanvasCompareDraftLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: 'Rascunho — o lado editável da comparação',
      child: Semantics(
        label: 'Rascunho — o lado editável da comparação',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_outlined,
              size: AppIconSizes.s16,
              color: colors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text('Rascunho', style: TextStyle(color: colors.inkPrimary)),
          ],
        ),
      ),
    );
  }
}
