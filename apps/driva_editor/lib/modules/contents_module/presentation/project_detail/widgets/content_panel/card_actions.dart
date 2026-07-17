import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:flutter/material.dart';

class CardActions extends StatelessWidget {
  const CardActions({
    required this.content,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Editar conteúdo',
          child: InkWell(
            onTap: () => onEdit(content),
            borderRadius: BorderRadius.circular(AppRadii.r7),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Icon(
                Icons.edit_outlined,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Mover conteúdo para outra categoria',
          child: InkWell(
            onTap: () => onMove(content),
            borderRadius: BorderRadius.circular(AppRadii.r7),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Icon(
                Icons.drive_file_move_outline,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Excluir conteúdo',
          child: InkWell(
            onTap: () => onDelete(content),
            borderRadius: BorderRadius.circular(AppRadii.r7),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Icon(
                Icons.delete_outline,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
