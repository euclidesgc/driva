import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: colors.inkMuted,
        ),
      ),
    );
  }
}
