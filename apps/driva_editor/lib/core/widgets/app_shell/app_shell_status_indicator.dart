import 'package:flutter/material.dart';

import '../../theme/editor_colors.dart';
import 'app_bar_action.dart';

class AppShellStatusIndicator extends StatelessWidget {
  const AppShellStatusIndicator({super.key, required this.status});

  final AppBarStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.tone) {
      AppBarStatusTone.success => Theme.of(
        context,
      ).extension<EditorColors>()!.success,
      AppBarStatusTone.neutral => scheme.onSurfaceVariant,
      AppBarStatusTone.danger => scheme.error,
    };
    return Semantics(
      liveRegion: true,
      label: 'Status: ${status.label}',
      child: Row(
        children: [
          Icon(status.icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
