import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/editor_colors.dart';
import 'drag_payload.dart';
import 'palette_icons.dart';

/// Árvore de widgets do conteúdo: seleção, remoção e drag-and-drop
/// (reordenar/aninhar nós, soltar itens da paleta).
class WidgetTreePanel extends StatelessWidget {
  const WidgetTreePanel({
    super.key,
    required this.root,
    required this.selectedNodeId,
    required this.onSelect,
    required this.onRemove,
    required this.onAddInto,
    required this.onMoveInto,
  });

  /// Raiz do conteúdo. `null` no conteúdo vazio — a árvore fica vazia e o único
  /// alvo de soltar é a zona que **define a raiz** (primeiro widget).
  final SduiNode? root;
  final String? selectedNodeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  /// Cria um nó da paleta dentro de `parentId` em `index`. Com `parentId` null
  /// (conteúdo vazio), o nó vira a raiz.
  final void Function(String type, String? parentId, int index) onAddInto;

  /// Move um nó existente para `parentId` em `index`.
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: rows,
          ),
        ),
        // Zona de soltar: no fim do conteúdo, ou — com o conteúdo vazio —
        // definindo o primeiro widget como raiz.
        _DropZone(
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
      _TreeRow(
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

  /// Soltar SOBRE um nó: quem aceita filhos recebe dentro (no fim); folha
  /// recebe como vizinho seguinte no pai.
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

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.isRoot,
    required this.isSelected,
    required this.onSelect,
    required this.onRemove,
    required this.onAccept,
  });

  final SduiNode node;
  final int depth;
  final bool isRoot;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;
  final ValueChanged<DragPayload> onAccept;

  String get _label {
    final descriptor = descriptorFor(node.type);
    final base = descriptor?.label ?? node.type;
    final text = node.properties['data'];
    if (node.type == 'text' && text is String && text.isNotEmpty) {
      return '$base — “$text”';
    }
    final buttonLabel = node.properties['label'];
    if (node.type == 'button' && buttonLabel is String) {
      return '$base — “$buttonLabel”';
    }
    return isRoot ? 'Conteúdo ($base)' : base;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final row = DragTarget<DragPayload>(
      onWillAcceptWithDetails: (details) => switch (details.data) {
        NodeDragPayload(:final nodeId) => nodeId != node.id,
        PaletteDragPayload() => true,
      },
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return Semantics(
          selected: isSelected,
          label: 'Bloco $_label',
          child: InkWell(
            onTap: onSelect,
            child: Container(
              padding: EdgeInsets.only(left: 12.0 + depth * 16, right: 4),
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primaryTint
                    : highlighted
                    ? colors.canvasBackdrop
                    : null,
                border: Border(
                  left: BorderSide(
                    width: 3,
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    paletteIconFor(node.type),
                    size: 16,
                    color: isSelected ? AppTheme.primary : colors.inkSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRemove != null && isSelected)
                    IconButton(
                      tooltip: 'Remover bloco (Delete)',
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onRemove,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return Draggable<DragPayload>(
      data: NodeDragPayload(node.id),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: AppTheme.primary),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(_label, style: const TextStyle(fontSize: 13)),
        ),
      ),
      child: row,
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.label, required this.onAccept});

  final String label;
  final ValueChanged<DragPayload> onAccept;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return DragTarget<DragPayload>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(12),
          height: 44,
          decoration: BoxDecoration(
            color: active ? colors.primaryTint : null,
            border: Border.all(
              color: active ? AppTheme.primary : colors.border,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppTheme.primary : colors.inkMuted,
              ),
            ),
          ),
        );
      },
    );
  }
}
