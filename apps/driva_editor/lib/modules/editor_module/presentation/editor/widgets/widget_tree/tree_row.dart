import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_content.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class TreeRow extends StatelessWidget {
  const TreeRow({
    required this.node,
    required this.depth,
    required this.isRoot,
    required this.isSelected,
    required this.onSelect,
    required this.onRemove,
    required this.onAccept,
    super.key,
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
      builder: (context, candidates, _) => TreeRowContent(
        isDragOver: candidates.isNotEmpty,
        isSelected: isSelected,
        label: _label,
        nodeType: node.type,
        depth: depth,
        onSelect: onSelect,
        onRemove: onRemove,
      ),
    );

    return Draggable<DragPayload>(
      data: NodeDragPayload(node.id),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s6,
          ),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: AppTheme.primary),
            borderRadius: BorderRadius.circular(AppRadii.r6),
          ),
          child: Text(
            _label,
            style: const TextStyle(fontSize: AppTypography.base),
          ),
        ),
      ),
      child: row,
    );
  }
}
