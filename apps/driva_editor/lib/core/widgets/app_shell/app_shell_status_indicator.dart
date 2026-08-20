import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:flutter/material.dart';

class AppShellStatusIndicator extends StatelessWidget {
  const AppShellStatusIndicator({required this.status, super.key});

  final AppBarStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.tone) {
      AppBarStatusTone.success => Theme.of(
        context,
      ).extension<EditorColors>()!.success,
      AppBarStatusTone.neutral => scheme.onSurfaceVariant,
      AppBarStatusTone.danger => scheme.error,
    };
    return Semantics(
      liveRegion: true,
      label: 'Status: ${status.label}',
      child: Tooltip(
        message: status.label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: AppIconSizes.s16, color: color),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                status.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: color, fontSize: AppTypography.base),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
