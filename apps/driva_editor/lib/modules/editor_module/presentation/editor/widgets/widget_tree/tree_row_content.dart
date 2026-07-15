import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../palette_icons.dart';

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
          padding: EdgeInsets.only(
            left: AppSpacing.s12 + depth * AppSpacing.s16,
            right: AppSpacing.s4,
          ),
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
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: AppTypography.base),
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
