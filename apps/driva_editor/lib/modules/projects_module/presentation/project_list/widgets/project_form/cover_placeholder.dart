import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/editor_colors.dart';

class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({super.key, required this.hovering});

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
