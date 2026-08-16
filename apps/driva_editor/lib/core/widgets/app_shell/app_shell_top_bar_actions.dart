import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_action_button.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_actions_overflow_menu.dart';
import 'package:flutter/material.dart';

/// Degradação em três peças da faixa de ações do shell (D35): em faixa
/// larga, cada ação aparece com ícone + rótulo; em faixa estreita, a única
/// ação `filled` da página permanece a um toque como ícone isolado, e todas
/// as demais colapsam no [AppShellActionsOverflowMenu].
class AppShellTopBarActions extends StatelessWidget {
  const AppShellTopBarActions({
    required this.actions,
    required this.compact,
    super.key,
  });

  final List<AppBarAction> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions) ...[
            AppShellActionButton(action: action),
            const SizedBox(width: AppSpacing.s8),
          ],
        ],
      );
    }

    AppBarAction? primary;
    final secondary = <AppBarAction>[];
    for (final action in actions) {
      if (primary == null && action.kind == AppBarActionKind.filled) {
        primary = action;
      } else {
        secondary.add(action);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (secondary.isNotEmpty) ...[
          AppShellActionsOverflowMenu(actions: secondary),
          const SizedBox(width: AppSpacing.s8),
        ],
        if (primary != null) ...[
          AppShellActionButton(action: primary, compact: true),
          const SizedBox(width: AppSpacing.s8),
        ],
      ],
    );
  }
}
