import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/crumb_label.dart';
import 'package:flutter/material.dart';

class AppShellBreadcrumbBar extends StatelessWidget {
  const AppShellBreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final controller = AppShellScope.watch(context);
    final crumbs = controller.crumbs;
    return Material(
      color: colors.panelAlt,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        alignment: Alignment.centerLeft,
        child: crumbs.isEmpty
            ? const SizedBox.shrink()
            : Row(
                children: [
                  for (var i = 0; i < crumbs.length; i++) ...[
                    if (i > 0)
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.inkMuted,
                      ),
                    CrumbLabel(
                      crumb: crumbs[i],
                      isLast: i == crumbs.length - 1,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
