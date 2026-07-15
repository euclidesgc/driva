import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/content_summary.dart';
import 'content_card.dart';
import 'content_row.dart';
import 'content_view_mode.dart';
import 'loading_more_footer.dart';

class ContentsCollection extends StatelessWidget {
  const ContentsCollection({
    super.key,
    required this.contents,
    required this.mode,
    required this.hasMore,
    required this.isLoadingMore,
    required this.categoryNameById,
    required this.onLoadMore,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final List<ContentSummary> contents;
  final ContentViewMode mode;
  final bool hasMore;
  final bool isLoadingMore;
  final Map<String, String> categoryNameById;
  final VoidCallback onLoadMore;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  /// Antecipa a próxima página ~1,5 tela antes do fim (rolagem sem "solavanco").
  static const _prefetchExtent = 400.0;

  bool _onScroll(ScrollNotification notification) {
    if (hasMore &&
        !isLoadingMore &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - _prefetchExtent) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Reserva espaço no rodapé para o loader não cobrir o último item.
    final bottomPadding = isLoadingMore ? 64.0 : AppSpacing.s24;
    final Widget collection = mode == ContentViewMode.list
        ? ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s24,
              bottomPadding,
            ),
            itemCount: contents.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) => ContentRow(
              content: contents[index],
              onOpen: onOpen,
              onEdit: onEdit,
              onMove: onMove,
              onDelete: onDelete,
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s24,
              bottomPadding,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: AppSpacing.s16,
              crossAxisSpacing: AppSpacing.s16,
              mainAxisExtent: 182,
            ),
            itemCount: contents.length,
            itemBuilder: (context, index) => ContentCard(
              content: contents[index],
              categoryName: categoryNameById[contents[index].categoryId],
              onOpen: onOpen,
              onEdit: onEdit,
              onMove: onMove,
              onDelete: onDelete,
            ),
          );

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          collection,
          if (isLoadingMore)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: LoadingMoreFooter(),
            ),
        ],
      ),
    );
  }
}
