import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/editor_colors.dart';
import '../branding/branding.dart';
import 'app_shell_action_button.dart';
import 'app_shell_scope.dart';
import 'app_shell_status_indicator.dart';

class AppShellTopBar extends StatelessWidget {
  const AppShellTopBar({
    super.key,
    required this.homeRouteName,
    required this.themeButton,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            AppWordmark(onTap: () => context.goNamed(homeRouteName)),
            const Spacer(),
            for (final action in controller.actions) ...[
              AppShellActionButton(action: action),
              const SizedBox(width: 8),
            ],
            if (controller.status case final status?) ...[
              AppShellStatusIndicator(status: status),
              const SizedBox(width: 12),
            ],
            themeButton,
          ],
        ),
      ),
    );
  }
}
