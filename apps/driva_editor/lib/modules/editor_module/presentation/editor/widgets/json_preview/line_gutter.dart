import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class LineGutter extends StatelessWidget {
  const LineGutter({
    required this.count,
    required this.style,
    required this.colors,
    super.key,
  });

  final int count;
  final TextStyle style;
  final EditorColors colors;

  @override
  Widget build(BuildContext context) {
    final numbers = [for (var i = 1; i <= count; i++) '$i'].join('\n');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Text(
        numbers,
        textAlign: TextAlign.right,
        style: style.copyWith(color: colors.inkMuted),
      ),
    );
  }
}
