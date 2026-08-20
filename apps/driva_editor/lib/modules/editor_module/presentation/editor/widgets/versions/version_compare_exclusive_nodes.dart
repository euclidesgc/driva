import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_exclusive_list.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// A seção de nós exclusivos (T5, item 50): "base à esquerda, candidata à
/// direita" no desktop; no compacto as duas colunas viram um controle
/// segmentado (nunca duas colunas espremidas) — esta é a única parte da
/// comparação com conteúdo genuinamente distinto por lado, por isso é a
/// única com o alternador. O lado escolhido é estado efêmero de exibição,
/// não pertence ao cubit.
class VersionCompareExclusiveNodes extends StatefulWidget {
  const VersionCompareExclusiveNodes({
    required this.onlyInBase,
    required this.onlyInCandidate,
    required this.baseSpec,
    required this.candidateSpec,
    required this.isCompact,
    super.key,
  });

  final Set<String> onlyInBase;
  final Set<String> onlyInCandidate;
  final ContentSpec baseSpec;
  final ContentSpec candidateSpec;
  final bool isCompact;

  @override
  State<VersionCompareExclusiveNodes> createState() =>
      _VersionCompareExclusiveNodesState();
}

class _VersionCompareExclusiveNodesState
    extends State<VersionCompareExclusiveNodes> {
  VersionCompareVisibleSide _visibleSide = VersionCompareVisibleSide.base;

  @override
  Widget build(BuildContext context) {
    if (widget.onlyInBase.isEmpty && widget.onlyInCandidate.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseColumn = VersionCompareExclusiveList(
      ids: widget.onlyInBase,
      spec: widget.baseSpec,
      kind: VersionCompareMarkerKind.onlyInBase,
      emptyLabel: 'Nenhum nó só no rascunho.',
    );
    final candidateColumn = VersionCompareExclusiveList(
      ids: widget.onlyInCandidate,
      spec: widget.candidateSpec,
      kind: VersionCompareMarkerKind.onlyInCandidate,
      emptyLabel: 'Nenhum nó só na versão.',
    );

    if (!widget.isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: baseColumn),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: candidateColumn),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<VersionCompareVisibleSide>(
          segments: const [
            ButtonSegment(
              value: VersionCompareVisibleSide.base,
              label: Text('Rascunho'),
            ),
            ButtonSegment(
              value: VersionCompareVisibleSide.candidate,
              label: Text('Versão'),
            ),
          ],
          selected: {_visibleSide},
          onSelectionChanged: (selection) =>
              setState(() => _visibleSide = selection.first),
        ),
        const SizedBox(height: AppSpacing.s8),
        if (_visibleSide == VersionCompareVisibleSide.base)
          baseColumn
        else
          candidateColumn,
      ],
    );
  }
}
