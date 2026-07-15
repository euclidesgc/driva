import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/content_summary.dart';
import 'card_actions.dart';
import 'category_label.dart';
import 'slug_badge.dart';
import 'support_id.dart';
import 'updated_at.dart';

/// Corpo visual do card de grade — o mesmo widget serve ao estado normal e ao
/// "ghost" esmaecido do arraste, variando só por [opacity] (recebida pelo
/// construtor). Extraído de `ContentCard` para não montar árvore por método.
class ContentCardBody extends StatelessWidget {
  const ContentCardBody({
    super.key,
    required this.content,
    this.categoryName,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.opacity = 1,
  });

  final ContentSummary content;
  final String? categoryName;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: opacity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(content),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s15,
              AppSpacing.s14,
              AppSpacing.s15,
              AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: SlugBadge(slug: content.slug)),
                    CardActions(
                      content: content,
                      onEdit: onEdit,
                      onMove: onMove,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s14),
                Text(
                  content.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                CategoryLabel(name: categoryName),
                const Spacer(),
                UpdatedAt(updatedAt: content.updatedAt),
                const SizedBox(height: AppSpacing.s3),
                SupportId(id: content.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
