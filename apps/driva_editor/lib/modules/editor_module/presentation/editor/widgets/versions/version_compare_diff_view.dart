import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_changed_nodes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_exclusive_nodes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_full_load_banner.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_summary_markers.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// O corpo da comparação quando os dois specs puderam ser indexados sem ID
/// duplicado (T5, item 50) — nós exclusivos, nós alterados em comum e, se
/// houver diferença que a seta não alcança, o aviso com a alternativa
/// segura (item 4 do plano).
class VersionCompareDiffView extends StatelessWidget {
  const VersionCompareDiffView({
    required this.result,
    required this.baseSpec,
    required this.candidateSpec,
    required this.canCopy,
    required this.isCompact,
    required this.onCopy,
    required this.onLoadFullVersion,
    super.key,
  });

  final SpecComparisonResult result;
  final ContentSpec baseSpec;
  final ContentSpec candidateSpec;
  final bool canCopy;
  final bool isCompact;
  final ValueChanged<String> onCopy;
  final VoidCallback onLoadFullVersion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final reasons = _uncopyableReasons(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!result.hasDifferences)
          Text(
            'Nenhuma diferença entre o rascunho e esta versão.',
            style: TextStyle(color: colors.inkSecondary),
          ),
        VersionCompareSummaryMarkers(
          safeAreaChanged: result.safeAreaChanged,
          changedMetadataFields: result.changedContentMetadataFields,
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          VersionCompareFullLoadBanner(
            reasons: reasons,
            onPressed: onLoadFullVersion,
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        Text('Nós exclusivos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        VersionCompareExclusiveNodes(
          onlyInBase: result.nodesOnlyInBase,
          onlyInCandidate: result.nodesOnlyInCandidate,
          baseSpec: baseSpec,
          candidateSpec: candidateSpec,
          isCompact: isCompact,
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'Nós em comum alterados',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.s8),
        VersionCompareChangedNodes(
          nodeDiffs: result.nodeDiffs,
          canCopy: canCopy,
          onCopy: onCopy,
        ),
      ],
    );
  }
}

List<String> _uncopyableReasons(SpecComparisonResult result) {
  final reasons = <String>[];
  if (result.nodesOnlyInBase.isNotEmpty ||
      result.nodesOnlyInCandidate.isNotEmpty) {
    reasons.add('estrutura');
  }
  if (result.nodeDiffs.any((diff) => diff.typeChanged)) reasons.add('tipo');
  if (result.nodeDiffs.any((diff) => diff.eventsChanged)) {
    reasons.add('eventos');
  }
  if (result.safeAreaChanged) reasons.add('safe area');
  if (result.changedContentMetadataFields.isNotEmpty) {
    reasons.add('metadados');
  }
  return reasons;
}
