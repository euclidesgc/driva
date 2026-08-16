import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class ColorPreviewSwatch extends StatelessWidget {
  const ColorPreviewSwatch({
    required this.color,
    required this.onTap,
    super.key,
  });

  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: 'Abrir seletor de cores',
      child: Semantics(
        button: true,
        label: color == null
            ? 'Sem cor definida, abrir seletor de cores'
            : 'Cor atual, abrir seletor de cores',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.r4),
          child: Container(
            width: AppSpacing.s24,
            height: AppSpacing.s24,
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(AppRadii.r4),
            ),
            child: color == null
                ? Icon(
                    Icons.format_color_reset_outlined,
                    size: AppIconSizes.s14,
                    color: colors.inkMuted,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
