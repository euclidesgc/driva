import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
import 'package:flutter/material.dart';

/// Cabeçalho de `VersionReviewDialog`: número, data e nota da versão, com o
/// selo de somente leitura sempre visível ao lado do número — o plano exige
/// os três dados nesta tela (item 50, T3).
class VersionReviewHeader extends StatelessWidget {
  const VersionReviewHeader({required this.version, super.key});

  final LoadedContentVersion version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(
      version.createdAt,
    );
    final note = version.note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Versão ${version.version}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            const VersionReadonlyBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          formatted,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
