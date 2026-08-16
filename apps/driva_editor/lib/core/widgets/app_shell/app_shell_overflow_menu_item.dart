import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:flutter/material.dart';

/// Conteúdo de um item do `AppShellActionsOverflowMenu`. Ícone opcional
/// (ações `AppBarAction.icon` sempre têm) + rótulo — cai para o `tooltip`
/// quando a ação não publica `label` (caso das ações icon-only do topo).
class AppShellOverflowMenuItem extends StatelessWidget {
  const AppShellOverflowMenuItem({required this.action, super.key});

  final AppBarAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = action.onPressed != null;
    final color = enabled ? null : theme.disabledColor;
    final label = action.label ?? action.tooltip ?? '';
    final icon = action.icon;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSizes.s18, color: color),
          const SizedBox(width: AppSpacing.s12),
        ],
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
