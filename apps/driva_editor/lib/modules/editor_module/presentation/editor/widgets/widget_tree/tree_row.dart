import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/remove_node_labels.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_node_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_content.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class TreeRow extends StatelessWidget {
  const TreeRow({
    required this.node,
    required this.depth,
    required this.isRoot,
    required this.isSelected,
    required this.diagnostics,
    required this.onSelect,
    required this.onRemove,
    required this.onAccept,
    this.diffMarkerKind,
    this.isDraggable = true,
    super.key,
  });

  final SduiNode node;
  final int depth;
  final bool isRoot;
  final bool isSelected;
  final List<SpecDiagnostic> diagnostics;
  final VersionCompareMarkerKind? diffMarkerKind;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;
  final ValueChanged<DragPayload> onAccept;

  /// Falso enquanto o rascunho está congelado: a linha continua selecionável
  /// para leitura, mas reordenar por arraste é edição.
  final bool isDraggable;

  String get _label => treeNodeLabel(node, isRoot: isRoot);

  String get _removeLabel => isRoot ? clearContentLabel : removeNodeLabel;

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
        diagnostics: diagnostics,
        diffMarkerKind: diffMarkerKind,
        onSelect: onSelect,
        onRemove: onRemove,
        removeLabel: _removeLabel,
      ),
    );

    if (!isDraggable) return row;

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
