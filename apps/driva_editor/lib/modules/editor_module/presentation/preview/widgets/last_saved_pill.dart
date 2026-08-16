import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:flutter/material.dart';

/// A pílula da D4: o conteúdo mostrado é sempre o último salvo (não há
/// autosave), mas o `HH:MM` que ela exibe é o instante da **busca**, não do
/// save — o `ContentSpec` não carrega `updatedAt`. Salvar de novo no desktop
/// sem puxar aqui não muda nada, e puxar aqui sem ter salvo de novo também
/// não muda nada — só o relógio andaria se o texto prometesse "salvo".
///
/// Desde a D30, o gesto de atualizar é o `RefreshIndicator` da tela — esta
/// pílula é só rótulo, sem `InkWell` nem afordância de toque.
class LastSavedPill extends StatelessWidget {
  const LastSavedPill({required this.fetchedAt, super.key});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label = 'Último salvo às ${DateFormatUtil.hourMinute(fetchedAt)}';
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: AppIconSizes.s18,
              color: colors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.base,
                color: colors.inkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
