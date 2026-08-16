import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:flutter/material.dart';

/// A pílula da D4: o conteúdo mostrado é sempre o último salvo (não há
/// autosave), mas o `HH:MM` que ela exibe é o instante da **busca**, não do
/// save — o `ContentSpec` não carrega `updatedAt`. Por isso o rótulo diz
/// "verificado", não "salvo": salvar de novo no desktop sem tocar aqui não
/// muda nada, e tocar aqui sem ter salvo de novo também não muda nada — só o
/// relógio andaria se o texto prometesse "salvo".
///
/// A afordância de toque é texto **visível**, não só `Tooltip`/`Semantics`:
/// o alvo é um aparelho de toque, que não tem hover.
class LastSavedPill extends StatelessWidget {
  const LastSavedPill({
    required this.fetchedAt,
    required this.onReload,
    super.key,
  });

  final DateTime fetchedAt;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final timeLabel = 'Verificado às ${DateFormatUtil.hourMinute(fetchedAt)}';
    const affordanceLabel = 'toque para atualizar';
    return Tooltip(
      message: '$timeLabel — $affordanceLabel',
      child: Semantics(
        button: true,
        label: '$timeLabel. Toque para atualizar.',
        child: Material(
          color: colors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onReload,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: AppIconSizes.s18,
                    color: colors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: timeLabel,
                          style: TextStyle(
                            fontSize: AppTypography.base,
                            color: colors.inkPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' · $affordanceLabel',
                          style: TextStyle(
                            fontSize: AppTypography.sm,
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
