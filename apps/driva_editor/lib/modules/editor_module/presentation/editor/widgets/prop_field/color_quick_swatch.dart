import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class ColorQuickSwatch extends StatelessWidget {
  const ColorQuickSwatch({
    required this.hex,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String hex;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: hex,
      child: Semantics(
        button: true,
        label: 'Cor $hex',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.r4),
          child: Container(
            width: AppSpacing.s18,
            height: AppSpacing.s18,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(AppRadii.r4),
            ),
          ),
        ),
      ),
    );
  }
}
