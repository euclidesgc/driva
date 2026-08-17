import 'package:driva_editor/core/theme/theme.dart';
import 'package:flutter/material.dart';

class EditorLoadFailureContent extends StatelessWidget {
  const EditorLoadFailureContent({
    required this.message,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSizes.s40, color: color),
        const SizedBox(height: AppSpacing.s12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.s12),
        OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
