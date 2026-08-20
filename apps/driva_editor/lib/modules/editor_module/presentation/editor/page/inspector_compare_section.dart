import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/canvas_compare_binding.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Liga o cabeçalho de comparação ao modo, por fora do `InspectorVm`.
///
/// O dado de comparação **não** entra no `InspectorVm` de propósito: o `==` e
/// o `hashCode` de lá são escritos à mão, e um campo novo passaria despercebido
/// por eles — o Inspector deixaria de reconstruir ao trocar de versão, sem
/// nenhum sinal de que faltava.
class InspectorCompareSection extends StatelessWidget {
  const InspectorCompareSection({required this.nodeId, super.key});

  /// `null` no modo página: só safe area e metadados são da página.
  final String? nodeId;

  @override
  Widget build(BuildContext context) {
    return CanvasCompareBinding(
      builder: (context, state, cubit) {
        if (state is! VersionCompareModeActive || cubit == null) {
          return const SizedBox.shrink();
        }
        return state.result.fold(
          (_) => const SizedBox.shrink(),
          (comparison) => InspectorCompareHeader(
            nodeId: nodeId,
            diff: _diffFor(comparison, nodeId),
            isOnlyInDraft:
                nodeId != null && comparison.nodesOnlyInBase.contains(nodeId),
            isOnlyInVersion:
                nodeId != null &&
                comparison.nodesOnlyInCandidate.contains(nodeId),
            safeAreaChanged: nodeId == null && comparison.safeAreaChanged,
            changedMetadataFields: nodeId == null
                ? comparison.changedContentMetadataFields
                : const {},
            candidateVersion: state.candidate.version,
            onCopyNodeProperties: cubit.copyNodeProperties,
          ),
        );
      },
    );
  }
}

NodeDiff? _diffFor(SpecComparisonResult comparison, String? nodeId) {
  if (nodeId == null) return null;
  for (final diff in comparison.nodeDiffs) {
    if (diff.nodeId == nodeId) return diff;
  }
  return null;
}
