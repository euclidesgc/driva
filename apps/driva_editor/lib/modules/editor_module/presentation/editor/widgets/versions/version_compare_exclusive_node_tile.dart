import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';

/// Um nó que existe só de um lado (T5, item 50) — nunca tem seta: inserir
/// ou remover subárvore é merge estrutural, fora do recorte da v1.
class VersionCompareExclusiveNodeTile extends StatelessWidget {
  const VersionCompareExclusiveNodeTile({
    required this.nodeId,
    required this.nodeType,
    required this.kind,
    this.labelOverride,
    super.key,
  });

  final String nodeId;
  final String? nodeType;
  final VersionCompareMarkerKind kind;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VersionCompareMarkerChip(kind: kind, labelOverride: labelOverride),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              nodeType == null ? nodeId : '$nodeId ($nodeType)',
              softWrap: true,
              style: TextStyle(
                color: colors.inkSecondary,
                fontSize: AppTypography.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
