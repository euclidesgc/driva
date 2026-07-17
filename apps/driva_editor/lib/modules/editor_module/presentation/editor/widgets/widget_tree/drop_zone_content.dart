import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class DropZoneContent extends StatelessWidget {
  const DropZoneContent({
    required this.isDragOver,
    required this.label,
    super.key,
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
