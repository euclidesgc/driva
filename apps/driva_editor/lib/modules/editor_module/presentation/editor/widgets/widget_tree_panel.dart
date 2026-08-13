import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class WidgetTreePanel extends StatelessWidget {
  const WidgetTreePanel({
    required this.root,
    required this.selectedNodeId,
    required this.onSelect,
    required this.onRemove,
    required this.onDropNew,
    required this.onDropMove,
    required this.onDropNewAt,
    required this.onDropMoveAt,
    super.key,
  });

  final SduiNode? root;

  /// `null` = a página (área segura) está no Inspector.
  final String? selectedNodeId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onRemove;

  /// Com `targetId` null (conteúdo vazio), o nó vira a raiz.
  final void Function(String type, String? targetId) onDropNew;

  final void Function(String nodeId, String targetId) onDropMove;

  /// Frestas entre linhas: posição exata dentro da lista de filhos do pai.
  final void Function(String type, String parentId, int index) onDropNewAt;

  final void Function(String nodeId, String parentId, int index) onDropMoveAt;

  @override
  Widget build(BuildContext context) {
    final root = this.root;
    final rows = <Widget>[];
    if (root != null) _buildRows(rows, root, root, depth: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTreeRow(
          isSelected: selectedNodeId == null,
          onSelect: () => onSelect(null),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            children: rows,
          ),
        ),
        DropZone(
          label: root == null
              ? 'Solte um widget aqui para começar'
              : 'Soltar aqui adiciona ao fim do conteúdo',
          onAccept: (payload) => switch (payload) {
            PaletteDragPayload(:final type) => onDropNew(type, root?.id),
            NodeDragPayload(:final nodeId) when root != null => onDropMove(
              nodeId,
              root.id,
            ),
            NodeDragPayload() => null,
          },
        ),
      ],
    );
  }

  void _buildRows(
    List<Widget> rows,
    SduiNode root,
    SduiNode node, {
    required int depth,
  }) {
    rows.add(
      TreeRow(
        node: node,
        depth: depth,
        isRoot: node.id == root.id,
        isSelected: node.id == selectedNodeId,
        onSelect: () => onSelect(node.id),
        onRemove: () => onRemove(node.id),
        onAccept: (payload) => switch (payload) {
          PaletteDragPayload(:final type) => onDropNew(type, node.id),
          NodeDragPayload(:final nodeId) => onDropMove(nodeId, node.id),
        },
      ),
    );
    if (node.child != null) {
      _buildRows(rows, root, node.child!, depth: depth + 1);
    }

    final acceptsList =
        (descriptorFor(node.type)?.slot ?? SlotKind.none) == SlotKind.multi;
    for (var index = 0; index <= node.children.length; index++) {
      if (acceptsList) {
        rows.add(
          TreeGapDropZone(
            key: ValueKey('gap_${node.id}_$index'),
            depth: depth + 1,
            parentId: node.id,
            index: index,
            onDropNew: onDropNewAt,
            onDropMove: onDropMoveAt,
          ),
        );
      }
      if (index < node.children.length) {
        _buildRows(rows, root, node.children[index], depth: depth + 1);
      }
    }
  }
}
