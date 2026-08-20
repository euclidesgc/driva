import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row_actions.dart';
import 'package:flutter/material.dart';

/// A linha de um ponto marcado ao salvar, na mesma lista das publicações.
///
/// Não tem número: `vN` é o que o usuário lê como "no ar (v3)", e só
/// publicação o consome. O que identifica um ponto é a nota que o autor
/// escreveu — por isso ela vem no lugar de destaque, onde a versão põe o
/// número.
///
/// O selo diz **"Não foi ao ar"** em texto, além do ícone: distinguir as duas
/// espécies só por cor deixaria a diferença invisível para quem não a
/// enxerga, e a diferença aqui é a mais importante da tela.
class CheckpointRow extends StatelessWidget {
  const CheckpointRow({
    required this.checkpoint,
    this.onView,
    this.onLoadToDraft,
    this.onCompare,
    super.key,
  });

  final ContentCheckpoint checkpoint;

  /// Nulos enquanto ver e carregar um ponto marcado não existirem: botão que
  /// não faz nada é pior que botão ausente, porque promete algo que não
  /// acontece.
  final ValueChanged<String>? onView;
  final ValueChanged<String>? onLoadToDraft;
  final ValueChanged<String>? onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final note = checkpoint.note;
    final view = onView;
    final loadToDraft = onLoadToDraft;
    final compare = onCompare;

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
              Icon(
                Icons.bookmark_outline,
                size: AppIconSizes.s13,
                color: colors.inkSecondary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Flexible(
                child: Text(
                  note == null || note.isEmpty ? 'Ponto salvo' : note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Não foi ao ar',
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            DateFormatUtil.dayMonthYearHourMinute(checkpoint.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (view != null && loadToDraft != null) ...[
            const SizedBox(height: AppSpacing.s8),
            VersionRowActions(
              onView: () => view(checkpoint.id),
              onLoadToDraft: () => loadToDraft(checkpoint.id),
              onCompare: compare == null ? null : () => compare(checkpoint.id),
            ),
          ],
        ],
      ),
    );
  }
}
