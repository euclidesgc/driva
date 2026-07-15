import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';
import '../palette_icons.dart';

class InspectorHeader extends StatelessWidget {
  const InspectorHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconType,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final String? iconType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(
            iconType == null ? Icons.web_asset : paletteIconFor(iconType!),
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remover bloco (Delete)',
              iconSize: 18,
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
