import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';

/// Uma ação de `VersionRow`. `isPrimary` decide o estilo Material (tonal vs.
/// texto) — nunca só cor — e `onPressed` nulo desabilita o botão mantendo o
/// lugar dela visível (Comparar, T3, aguarda o motor da T4).
class VersionRowActionButton extends StatelessWidget {
  const VersionRowActionButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, size: AppIconSizes.s18);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: label,
        child: isPrimary
            ? FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: child,
                label: Text(label),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: child,
                label: Text(label),
              ),
      ),
    );
  }
}
