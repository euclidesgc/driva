import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/palette_icons.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_node_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diff_marker.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Linha-fantasma da árvore no modo de comparação: um nó que só existe na
/// versão comparada não tem linha própria no rascunho, e sem representação a
/// diferença sumiria da tela. É somente leitura — não seleciona, não arrasta,
/// não remove: o nó não está no documento para receber gesto nenhum.
class CompareGhostTreeRow extends StatelessWidget {
  const CompareGhostTreeRow({required this.node, super.key});

  final SduiNode node;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label = treeNodeLabel(node);
    return Semantics(
      label: 'Somente na versão: $label',
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.s12,
          right: AppSpacing.s4,
        ),
        height: 34,
        child: Row(
          children: [
            Icon(paletteIconFor(node.type), size: 16, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.base,
                  color: colors.inkMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.s4),
              child: TreeRowDiffMarker(
                kind: VersionCompareMarkerKind.onlyInCandidate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
