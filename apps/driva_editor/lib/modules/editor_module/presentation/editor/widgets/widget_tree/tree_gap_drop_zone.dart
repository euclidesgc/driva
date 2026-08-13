import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_gap_indicator.dart';
import 'package:flutter/material.dart';

/// Soltar sobre uma linha encaixa "dentro ou depois" dela; a fresta é o que
/// permite escolher **qualquer** posição da lista — inclusive a primeira.
class TreeGapDropZone extends StatelessWidget {
  const TreeGapDropZone({
    required this.depth,
    required this.parentId,
    required this.index,
    required this.onDropNew,
    required this.onDropMove,
    super.key,
  });

  final int depth;
  final String parentId;
  final int index;
  final void Function(String type, String parentId, int index) onDropNew;
  final void Function(String nodeId, String parentId, int index) onDropMove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragPayload>(
      onAcceptWithDetails: (details) => switch (details.data) {
        PaletteDragPayload(:final type) => onDropNew(type, parentId, index),
        NodeDragPayload(:final nodeId) => onDropMove(nodeId, parentId, index),
      },
      builder: (context, candidates, _) =>
          TreeGapIndicator(depth: depth, isActive: candidates.isNotEmpty),
    );
  }
}
