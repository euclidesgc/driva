import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_base_phrases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_exclusive_list.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// A seção de nós exclusivos (T5, item 50): "base à esquerda, candidata à
/// direita" no desktop; no compacto, só a coluna escolhida em
/// [visibleSide] — nunca duas colunas espremidas. [visibleSide] é
/// controlado por fora (`VersionCompareLoadedBody`), pelo mesmo
/// `VersionCompareSideToggle` que decide qual preview aparece — um único
/// alternador para as duas seções, não um por seção.
class VersionCompareExclusiveNodes extends StatelessWidget {
  const VersionCompareExclusiveNodes({
    required this.onlyInBase,
    required this.onlyInCandidate,
    required this.baseSpec,
    required this.candidateSpec,
    required this.isCompact,
    required this.visibleSide,
    required this.base,
    required this.publishedVersion,
    super.key,
  });

  final Set<String> onlyInBase;
  final Set<String> onlyInCandidate;
  final ContentSpec baseSpec;
  final ContentSpec candidateSpec;
  final bool isCompact;
  final VersionCompareVisibleSide visibleSide;

  /// Quem está sendo exibida como base (rascunho ou a versão no ar) — o
  /// rótulo de `onlyInBase` nomeia ela por extenso, nunca "rascunho" fixo.
  final VersionComparisonBase base;
  final int? publishedVersion;

  @override
  Widget build(BuildContext context) {
    if (onlyInBase.isEmpty && onlyInCandidate.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseColumn = VersionCompareExclusiveList(
      ids: onlyInBase,
      spec: baseSpec,
      kind: VersionCompareMarkerKind.onlyInBase,
      emptyLabel: 'Nenhum nó só ${baseLocationPhrase(base, publishedVersion)}.',
      labelOverride: 'Somente ${baseLocationPhrase(base, publishedVersion)}',
    );
    final candidateColumn = VersionCompareExclusiveList(
      ids: onlyInCandidate,
      spec: candidateSpec,
      kind: VersionCompareMarkerKind.onlyInCandidate,
      emptyLabel: 'Nenhum nó só na versão.',
    );

    if (!isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: baseColumn),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: candidateColumn),
        ],
      );
    }

    return visibleSide == VersionCompareVisibleSide.base
        ? baseColumn
        : candidateColumn;
  }
}
