import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

/// Traduz o estado do modo de comparação nos parâmetros de diff do
/// `WidgetTreePanel`: índice por nó, exclusivos do rascunho, fantasmas da
/// versão e marcadores da linha da página. Fora do modo (ou com a comparação
/// bloqueada por IDs duplicados) entrega o painel limpo.
class CompareAwareWidgetTree extends StatelessWidget {
  const CompareAwareWidgetTree({
    required this.state,
    required this.cubit,
    this.compareState = const VersionCompareModeInactive(),
    super.key,
  });

  final EditorReady state;
  final EditorCubit cubit;
  final VersionCompareModeState compareState;

  @override
  Widget build(BuildContext context) {
    final active = compareState;
    final comparison = active is VersionCompareModeActive
        ? active.result.getRight().toNullable()
        : null;
    return WidgetTreePanel(
      root: state.document.root,
      isReadOnly: state.isReadOnly,
      selectedNodeId: state.selectedNodeId,
      nodeDiagnostics: diagnosticsByNode(state.diagnostics),
      compareDiffs: comparison == null
          ? const {}
          : {for (final diff in comparison.nodeDiffs) diff.nodeId: diff},
      compareOnlyInBase: comparison?.nodesOnlyInBase ?? const {},
      compareGhostNodes:
          active is VersionCompareModeActive && comparison != null
          ? _nodesInTreeOrder(
              active.candidate.spec,
              comparison.nodesOnlyInCandidate,
            )
          : const [],
      pageDiffMarkers: [
        if (comparison?.safeAreaChanged ?? false)
          VersionCompareMarkerKind.safeAreaChanged,
        if (comparison?.changedContentMetadataFields.isNotEmpty ?? false)
          VersionCompareMarkerKind.metadataChanged,
      ],
      onSelect: cubit.selectNode,
      onRemove: cubit.removeNode,
      onDropNew: (type, targetId) => cubit.addNode(type, targetId: targetId),
      onDropMove: cubit.moveNode,
      onDropNewAt: cubit.addNodeAt,
      onDropMoveAt: cubit.moveNodeAt,
    );
  }
}

List<SduiNode> _nodesInTreeOrder(ContentSpec spec, Set<String> ids) {
  final nodes = <SduiNode>[];
  void visit(SduiNode node) {
    if (ids.contains(node.id)) nodes.add(node);
    final child = node.child;
    if (child != null) visit(child);
    node.children.forEach(visit);
  }

  final root = spec.root;
  if (root != null) visit(root);
  return nodes;
}
