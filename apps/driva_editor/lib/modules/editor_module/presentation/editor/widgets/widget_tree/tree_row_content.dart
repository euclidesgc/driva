import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../palette_icons.dart';

/// Corpo do `builder:` do [DragTarget] de uma linha da árvore: a linha em si
/// (ícone + rótulo + ação de remover), com o realce de drag-over derivado de
/// [isDragOver] (`candidates.isNotEmpty` no callback).
class TreeRowContent extends StatelessWidget {
  const TreeRowContent({
    super.key,
    required this.isDragOver,
    required this.isSelected,
    required this.label,
    required this.nodeType,
    required this.depth,
    required this.onSelect,
    required this.onRemove,
  });

  final bool isDragOver;
  final bool isSelected;
  final String label;
  final String nodeType;
  final int depth;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final highlighted = isDragOver;
    return Semantics(
      selected: isSelected,
      label: 'Bloco $label',
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
                paletteIconFor(nodeType),
                size: 16,
                color: isSelected ? AppTheme.primary : colors.inkSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
  }
}
