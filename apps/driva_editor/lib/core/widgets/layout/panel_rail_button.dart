import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';

class PanelRailButton extends StatelessWidget {
  const PanelRailButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Tooltip e rótulo de acessibilidade — a única pista de qual aba o ícone
  /// reabre, já que a cor/ícone sozinhos não podem carregar essa informação.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      iconSize: AppIconSizes.s18,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
