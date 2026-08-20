import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';

/// Diferenças de nível de conteúdo — `safeArea` e metadados (T5, item 50) —
/// nunca aparecem como iguais por omissão: quando diferem, o chip some só
/// quando não há diferença alguma, nunca escondido por outro motivo.
class VersionCompareSummaryMarkers extends StatelessWidget {
  const VersionCompareSummaryMarkers({
    required this.safeAreaChanged,
    required this.changedMetadataFields,
    super.key,
  });

  final bool safeAreaChanged;
  final Set<String> changedMetadataFields;

  @override
  Widget build(BuildContext context) {
    if (!safeAreaChanged && changedMetadataFields.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        if (safeAreaChanged)
          const VersionCompareMarkerChip(
            kind: VersionCompareMarkerKind.safeAreaChanged,
          ),
        if (changedMetadataFields.isNotEmpty)
          const VersionCompareMarkerChip(
            kind: VersionCompareMarkerKind.metadataChanged,
          ),
      ],
    );
  }
}
