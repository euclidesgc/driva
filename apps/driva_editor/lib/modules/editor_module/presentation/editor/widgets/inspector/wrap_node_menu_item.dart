import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/palette_icons.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Conteúdo de um item do menu de envolver. O atalho só aparece no item
/// Column (D8) — a Row fica sem [shortcutLabel] de propósito, para a
/// assimetria virar informação visível em vez de surpresa descoberta sozinha.
class WrapNodeMenuItem extends StatelessWidget {
  const WrapNodeMenuItem({
    required this.wrapperType,
    this.shortcutLabel,
    super.key,
  });

  final String wrapperType;
  final String? shortcutLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Row(
      children: [
        Icon(paletteIconFor(wrapperType), size: AppIconSizes.s18),
        const SizedBox(width: AppSpacing.s8),
        Text(descriptorFor(wrapperType)?.label ?? wrapperType),
        const Spacer(),
        if (shortcutLabel != null)
          Text(
            shortcutLabel!,
            style: TextStyle(
              fontSize: AppTypography.sm,
              color: colors.inkMuted,
            ),
          ),
      ],
    );
  }
}
