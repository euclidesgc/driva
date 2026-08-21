import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_draft_legend.dart';
import 'package:flutter/material.dart';

/// Metade esquerda de `VersionCompareModeBar`: mesma altura, cor e borda de
/// `VersionCompareCandidateBar`, para as duas metades lerem como uma barra
/// só, mesmo com um respiro entre elas alinhado ao vão entre os mocks.
class VersionCompareDraftLabel extends StatelessWidget {
  const VersionCompareDraftLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      height: AppSizes.canvasToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      alignment: Alignment.centerLeft,
      child: const CanvasCompareDraftLegend(),
    );
  }
}
