import 'package:flutter/material.dart';

class ThemeMenuItem extends StatelessWidget {
  const ThemeMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ),
        if (selected)
          Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
      ],
    );
  }
}
