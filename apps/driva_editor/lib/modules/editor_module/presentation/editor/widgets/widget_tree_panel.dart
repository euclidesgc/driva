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
    required this.onAddInto,
    required this.onMoveInto,
    super.key,
  });

  final SduiNode? root;
  final String? selectedNodeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  /// Com `parentId` null (conteúdo vazio), o nó vira a raiz.
  final void Function(String type, String? parentId, int index) onAddInto;

  final void Function(String nodeId, String parentId, int index) onMoveInto;

  @override
  Widget build(BuildContext context) {
    final root = this.root;
    final rows = <Widget>[];
    if (root != null) _buildRows(rows, root, root, depth: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            PaletteDragPayload(:final type) => onAddInto(
              type,
              root?.id,
              root?.children.length ?? 0,
            ),
            NodeDragPayload(:final nodeId) when root != null => onMoveInto(
              nodeId,
              root.id,
              root.children.length,
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
        onAccept: (payload) => _dropOn(root, node, payload),
      ),
    );
    if (node.child != null) {
      _buildRows(rows, root, node.child!, depth: depth + 1);
    }
    for (final child in node.children) {
      _buildRows(rows, root, child, depth: depth + 1);
    }
  }

  void _dropOn(SduiNode root, SduiNode target, DragPayload payload) {
    final slot = descriptorFor(target.type)?.slot ?? SlotKind.none;
    final acceptsChildren =
        slot == SlotKind.multi ||
        (slot == SlotKind.single && target.child == null);

    final String parentId;
    final int index;
    if (acceptsChildren) {
      parentId = target.id;
      index = target.children.length;
    } else {
      final parent = findParent(root, target.id) ?? root;
      final position = parent.children.indexWhere((c) => c.id == target.id);
      parentId = parent.id;
      index = position >= 0 ? position + 1 : parent.children.length;
    }

    switch (payload) {
      case PaletteDragPayload(:final type):
        onAddInto(type, parentId, index);
      case NodeDragPayload(:final nodeId):
        onMoveInto(nodeId, parentId, index);
    }
  }
}
