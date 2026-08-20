import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:flutter/material.dart';

/// Cabeçalho de `VersionCompareDialog` (T5, item 50): identifica a
/// candidata e deixa trocar a base exibida entre rascunho e versão no ar
/// — o padrão (item 1 do plano). A cópia continua só possível com o
/// rascunho como base; o aviso abaixo do controle declara isso quando a
/// base exibida é a versão no ar.
class VersionCompareHeader extends StatelessWidget {
  const VersionCompareHeader({
    required this.candidate,
    required this.base,
    required this.hasPublishedVersion,
    required this.isLoadingPublishedBase,
    required this.onBaseChanged,
    super.key,
  });

  final LoadedContentVersion candidate;
  final VersionComparisonBase base;
  final bool hasPublishedVersion;
  final bool isLoadingPublishedBase;
  final ValueChanged<VersionComparisonBase> onBaseChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(
      candidate.createdAt,
    );

    final toggle = SegmentedButton<VersionComparisonBase>(
      segments: [
        const ButtonSegment(
          value: VersionComparisonBase.draft,
          label: Text('Rascunho'),
        ),
        ButtonSegment(
          value: VersionComparisonBase.published,
          label: const Text('No ar'),
          enabled: hasPublishedVersion,
        ),
      ],
      selected: {base},
      onSelectionChanged: isLoadingPublishedBase
          ? null
          : (selection) => onBaseChanged(selection.first),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparando com a versão ${candidate.version} ($formatted)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Base:', style: TextStyle(color: colors.inkSecondary)),
            const SizedBox(width: AppSpacing.s8),
            if (hasPublishedVersion)
              toggle
            else
              Tooltip(
                message: 'Nunca publicado — não há versão no ar para comparar.',
                child: toggle,
              ),
            if (isLoadingPublishedBase) ...[
              const SizedBox(width: AppSpacing.s8),
              const SizedBox(
                width: AppIconSizes.s16,
                height: AppIconSizes.s16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        if (base == VersionComparisonBase.published) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Comparando com a versão no ar — para copiar propriedades, '
            'volte para o rascunho.',
            style: TextStyle(
              color: colors.inkMuted,
              fontSize: AppTypography.sm,
            ),
          ),
        ],
      ],
    );
  }
}
