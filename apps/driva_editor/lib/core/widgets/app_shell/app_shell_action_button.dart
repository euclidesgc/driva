import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:flutter/material.dart';

class AppShellActionButton extends StatelessWidget {
  const AppShellActionButton({
    required this.action,
    this.compact = false,
    super.key,
  });

  final AppBarAction action;

  /// Faixa estreita da top bar (D35): a ação `filled` primária vira só
  /// ícone, ainda em destaque e a um toque — nunca some.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = action.icon;
    final label = action.label ?? '';
    final isCompactPrimary =
        compact && action.kind == AppBarActionKind.filled && icon != null;
    final button = isCompactPrimary
        ? IconButton.filled(
            onPressed: action.onPressed,
            icon: Icon(icon, size: AppIconSizes.s18),
          )
        : switch (action.kind) {
            AppBarActionKind.filled =>
              icon != null
                  ? FilledButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(icon, size: AppIconSizes.s18),
                      label: Text(label),
                    )
                  : FilledButton(
                      onPressed: action.onPressed,
                      child: Text(label),
                    ),
            AppBarActionKind.outlined =>
              icon != null
                  ? OutlinedButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(icon, size: AppIconSizes.s18),
                      label: Text(label),
                    )
                  : OutlinedButton(
                      onPressed: action.onPressed,
                      child: Text(label),
                    ),
            AppBarActionKind.text =>
              icon != null
                  ? TextButton.icon(
                      onPressed: action.onPressed,
                      icon: Icon(icon, size: AppIconSizes.s18),
                      label: Text(label),
                    )
                  : TextButton(onPressed: action.onPressed, child: Text(label)),
            AppBarActionKind.icon => IconButton(
              onPressed: action.onPressed,
              icon: Icon(icon),
            ),
          };
    final tooltip = action.tooltip ?? (isCompactPrimary ? label : null);
    if (tooltip == null || tooltip.isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
