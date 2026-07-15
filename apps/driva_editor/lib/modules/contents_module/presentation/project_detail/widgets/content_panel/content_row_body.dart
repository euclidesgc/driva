import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';
import '../../../../domain/entities/content_summary.dart';
import 'card_actions.dart';
import 'slug_badge.dart';
import 'updated_at.dart';

/// Corpo visual da linha (modo lista) — o mesmo widget serve ao estado normal
/// e ao "ghost" esmaecido do arraste, variando só por [opacity] (recebida pelo
/// construtor). Extraído de `ContentRow` para não montar árvore por método.
class ContentRowBody extends StatelessWidget {
  const ContentRowBody({
    super.key,
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.opacity = 1,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: colors.panel,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => onOpen(content),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                SlugBadge(slug: content.slug),
                const SizedBox(width: 14),
                // Título com espaço generoso: na lista ele não espreme (só
                // trunca em telas realmente estreitas), diferente do card de
                // grade que reserva espaço fixo para as ações.
                Expanded(
                  child: Text(
                    content.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                UpdatedAt(updatedAt: content.updatedAt),
                const SizedBox(width: 6),
                CardActions(
                  content: content,
                  onEdit: onEdit,
                  onMove: onMove,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
