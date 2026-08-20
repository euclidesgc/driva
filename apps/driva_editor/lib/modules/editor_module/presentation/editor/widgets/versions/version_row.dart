import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row_actions.dart';
import 'package:flutter/material.dart';

/// Uma linha do histórico: versão, data, nota (se houver), selo "No ar" e as
/// três ações da T3 (item 50) — `Ver`, `Comparar` e `Carregar no rascunho`.
/// Selecionar a linha em si não faz nada: só um botão explícito age.
class VersionRow extends StatelessWidget {
  const VersionRow({
    required this.version,
    required this.isPublished,
    required this.onView,
    required this.onLoadToDraft,
    this.onCompare,
    super.key,
  });

  final ContentVersion version;
  final bool isPublished;
  final ValueChanged<int> onView;
  final ValueChanged<int> onLoadToDraft;
  final ValueChanged<int>? onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(version.createdAt);
    final note = version.note;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Versão ${version.version}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isPublished) ...[
                const SizedBox(width: AppSpacing.s8),
                Icon(
                  Icons.public,
                  size: AppIconSizes.s13,
                  color: colors.success,
                ),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  'No ar',
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            formatted,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.inkSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.s8),
          VersionRowActions(
            onView: () => onView(version.version),
            onLoadToDraft: () => onLoadToDraft(version.version),
            onCompare: onCompare == null
                ? null
                : () => onCompare!(version.version),
          ),
        ],
      ),
    );
  }
}
