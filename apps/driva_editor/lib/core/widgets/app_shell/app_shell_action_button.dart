import 'package:flutter/material.dart';

import 'app_bar_action.dart';

class AppShellActionButton extends StatelessWidget {
  const AppShellActionButton({super.key, required this.action});

  final AppBarAction action;

  @override
  Widget build(BuildContext context) {
    final icon = action.icon;
    final label = action.label ?? '';
    final Widget button = switch (action.kind) {
      AppBarActionKind.filled =>
        icon != null
            ? FilledButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : FilledButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.outlined =>
        icon != null
            ? OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : OutlinedButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.text =>
        icon != null
            ? TextButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : TextButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.icon => IconButton(
        onPressed: action.onPressed,
        icon: Icon(icon),
      ),
    };
    final tooltip = action.tooltip;
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
