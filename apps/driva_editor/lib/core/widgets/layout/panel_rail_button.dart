import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class PanelRailButton extends StatelessWidget {
  const PanelRailButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    super.key,
  });

  final IconData icon;

  /// Tooltip e rótulo de acessibilidade — a única pista de qual aba o ícone
  /// reabre, já que a cor/ícone sozinhos não podem carregar essa informação.
  final String label;

  final VoidCallback onPressed;

  /// A aba correspondente é a atualmente aberta antes do colapso. O
  /// contorno abaixo, não só a cor do ícone, é o sinal — a mesma regra de
  /// acessibilidade que rege `TreeRowContent`/`PageTreeRow`.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Semantics(
      selected: isSelected,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryTint : null,
          borderRadius: BorderRadius.circular(AppRadii.r8),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : null,
        ),
        child: IconButton(
          tooltip: label,
          iconSize: AppIconSizes.s18,
          icon: Icon(icon, color: isSelected ? AppTheme.primary : null),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
