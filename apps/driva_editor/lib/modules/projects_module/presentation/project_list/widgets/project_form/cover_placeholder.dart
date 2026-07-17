import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({required this.hovering, super.key});

  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: hovering ? theme.colorScheme.primary : colors.inkMuted,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Arraste uma imagem de capa\nou clique para escolher',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
