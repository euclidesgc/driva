import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Selo do snapshot histórico em `VersionReviewDialog`: ícone + texto, nunca
/// só cor, para não depender de percepção de cor (o snapshot em si já é
/// travado por `AbsorbPointer`/`FocusScope` — este selo só declara isso).
class VersionReadonlyBadge extends StatelessWidget {
  const VersionReadonlyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message:
          'Este preview não aceita edição, toque nem navegação por '
          'teclado.',
      child: Semantics(
        label: 'Somente leitura',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: colors.panelAlt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: AppIconSizes.s13,
                color: colors.inkSecondary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                'Somente leitura',
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: colors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
