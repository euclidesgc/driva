import 'package:flutter/material.dart';

import '../../../domain/entities/content_summary.dart';
import 'category_tree_row.dart';

class CategoryRow extends StatefulWidget {
  const CategoryRow({
    super.key,
    required this.label,
    required this.icon,
    required this.depth,
    required this.hasChildren,
    required this.collapsed,
    required this.count,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.isAllContentsShortcut = false,
    required this.onAcceptContent,
  });

  final String label;
  final IconData icon;
  final int depth;
  final bool hasChildren;
  final bool collapsed;
  final int? count;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// `true` só para o pseudo-nó "Todos os conteúdos": não é uma categoria
  /// real, é um atalho de filtro. Ganha tratamento visual distinto (peso de
  /// fonte sempre marcado, sem contador tabular) para não ser confundido com
  /// irmão de "Geral" e demais categorias.
  final bool isAllContentsShortcut;

  /// Soltar um conteúdo arrastado sobre esta linha.
  /// `null` para o pseudo-nó "Todos os conteúdos": ele não vira
  /// `DragTarget`, nunca é alvo de drop.
  final ValueChanged<ContentSummary>? onAcceptContent;

  @override
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onAcceptContent != null) {
      return DragTarget<ContentSummary>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => widget.onAcceptContent!(details.data),
        builder: (context, candidateData, rejectedData) => CategoryTreeRow(
          label: widget.label,
          icon: widget.icon,
          depth: widget.depth,
          collapsed: widget.collapsed,
          count: widget.count,
          selected: widget.selected,
          isDropTarget: candidateData.isNotEmpty,
          hovered: _hovered,
          isAllContentsShortcut: widget.isAllContentsShortcut,
          onSelect: widget.onSelect,
          onToggle: widget.onToggle,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          onHoverChanged: (value) => setState(() => _hovered = value),
        ),
      );
    }
    return CategoryTreeRow(
      label: widget.label,
      icon: widget.icon,
      depth: widget.depth,
      collapsed: widget.collapsed,
      count: widget.count,
      selected: widget.selected,
      isDropTarget: false,
      hovered: _hovered,
      isAllContentsShortcut: widget.isAllContentsShortcut,
      onSelect: widget.onSelect,
      onToggle: widget.onToggle,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onHoverChanged: (value) => setState(() => _hovered = value),
    );
  }
}
