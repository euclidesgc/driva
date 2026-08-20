import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_copy_arrow_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Um nó presente nos dois lados com alguma diferença (T5, item 50): id,
/// marcadores aplicáveis e, só quando o tipo é o mesmo e há propriedade
/// diferente para trazer, a seta de cópia — nulo não desabilita, ela
/// simplesmente não existe. Layout único (sem coluna dupla): o `Wrap` dos
/// marcadores já evita corte de texto no compacto sem precisar de uma
/// variante própria.
class VersionCompareNodeRow extends StatelessWidget {
  const VersionCompareNodeRow({
    required this.diff,
    required this.onCopy,
    super.key,
  });

  final NodeDiff diff;

  /// Nulo faz a seta não existir — nó incompatível (tipo mudou) ou base
  /// exibida diferente do rascunho.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final markers = [
      if (diff.propertiesChanged) VersionCompareMarkerKind.propertiesChanged,
      if (diff.eventsChanged) VersionCompareMarkerKind.eventsChanged,
      if (diff.typeChanged) VersionCompareMarkerKind.typeChanged,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diff.typeChanged
                      ? '${diff.nodeId} '
                            '(${diff.baseType} → ${diff.candidateType})'
                      : '${diff.nodeId} (${diff.baseType})',
                  style: TextStyle(
                    color: colors.inkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: AppSpacing.s6),
                Wrap(
                  spacing: AppSpacing.s6,
                  runSpacing: AppSpacing.s6,
                  children: [
                    for (final marker in markers)
                      VersionCompareMarkerChip(kind: marker),
                  ],
                ),
              ],
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: AppSpacing.s8),
            VersionCompareCopyArrowButton(onPressed: onCopy!),
          ],
        ],
      ),
    );
  }
}
