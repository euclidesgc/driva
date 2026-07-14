import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/editor_colors.dart';

class ToggleButton extends StatelessWidget {
  const ToggleButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.r6),
          child: Container(
            width: 30,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primaryTint : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.r6),
              border: selected
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? theme.colorScheme.primary : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
