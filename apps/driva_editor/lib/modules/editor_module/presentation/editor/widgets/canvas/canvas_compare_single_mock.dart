import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_side.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_side_toggle.dart';
import 'package:flutter/material.dart';

/// A faixa estreita do modo de comparação: um mock por vez, com alternador.
///
/// Entra quando a escala calculada para dois mocks lado a lado cairia abaixo
/// do piso de legibilidade — o critério é a escala resultante, não uma
/// largura de janela, porque a mesma janela comporta dois smartphones e não
/// comporta dois tablets.
class CanvasCompareSingleMock extends StatelessWidget {
  const CanvasCompareSingleMock({
    required this.side,
    required this.candidateVersion,
    required this.onSideChanged,
    required this.draftPanel,
    required this.comparePane,
    super.key,
  });

  final CanvasCompareSide side;
  final int candidateVersion;
  final ValueChanged<CanvasCompareSide> onSideChanged;
  final Widget draftPanel;
  final Widget comparePane;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s8),
          color: colors.panelAlt,
          child: Center(
            child: CanvasCompareSideToggle(
              side: side,
              candidateVersion: candidateVersion,
              onChanged: onSideChanged,
            ),
          ),
        ),
        Expanded(
          child: side == CanvasCompareSide.draft ? draftPanel : comparePane,
        ),
      ],
    );
  }
}
