import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';

class DropZoneContent extends StatelessWidget {
  const DropZoneContent({
    super.key,
    required this.isDragOver,
    required this.label,
  });

  final bool isDragOver;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final active = isDragOver;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s12),
      height: 44,
      decoration: BoxDecoration(
        color: active ? colors.primaryTint : null,
        border: Border.all(
          color: active ? AppTheme.primary : colors.border,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.md,
            color: active ? AppTheme.primary : colors.inkMuted,
          ),
        ),
      ),
    );
  }
}
