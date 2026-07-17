import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_action_button.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_status_indicator.dart';
import 'package:driva_editor/core/widgets/branding/branding.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellTopBar extends StatelessWidget {
  const AppShellTopBar({
    required this.homeRouteName,
    required this.themeButton,
    super.key,
  });

  final String homeRouteName;
  final Widget themeButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final controller = AppShellScope.watch(context);
    return Material(
      color: colors.panel,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            AppWordmark(onTap: () => context.goNamed(homeRouteName)),
            const Spacer(),
            for (final action in controller.actions) ...[
              AppShellActionButton(action: action),
              const SizedBox(width: AppSpacing.s8),
            ],
            if (controller.status case final status?) ...[
              AppShellStatusIndicator(status: status),
              const SizedBox(width: AppSpacing.s12),
            ],
            themeButton,
          ],
        ),
      ),
    );
  }
}
