import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/history_entry_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
import 'package:flutter/material.dart';

/// Cabeçalho de `VersionReviewDialog`: título, data e nota, com o selo de
/// somente leitura sempre visível ao lado do título (item 50/53, T3). O
/// título já é a nota do ponto salvo quando a entrada é um checkpoint — por
/// isso ela não repete como linha extra, ao contrário de uma publicação.
class VersionReviewHeader extends StatelessWidget {
  const VersionReviewHeader({required this.entry, super.key});

  final LoadedHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(entry.createdAt);
    final note = entry.note;
    final showNoteSeparately = entry is LoadedContentVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              historyEntryTitle(entry),
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
        if (showNoteSeparately && note != null && note.isNotEmpty) ...[
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
