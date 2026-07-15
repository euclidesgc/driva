import 'package:fpdart/fpdart.dart';

import '../../../../core/dev/fake_contents_store.dart';
import '../../../../core/error/error.dart';
import '../../../../core/util/slug.dart';
import '../../domain/entities/content_sort.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/entities/contents_page.dart';
import '../../domain/repositories/contents_repository.dart';

class ContentsRepositoryFake implements ContentsRepository {
  final FakeContentsStore store;
  ContentsRepositoryFake(this.store);

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Either<Failure, ContentsPage>> getContents({
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
    String? cursor,
    int limit = 20,
  }) async {
    await Future<void>.delayed(_latency);
    if (limit < 1 || limit > 100) {
      return const Left(
        ValidationFailure('O limite deve estar entre 1 e 100.'),
      );
    }

    var summaries = [
      for (final content in store.contents)
        ContentSummary(
          id: content.id,
          name: content.name,
          slug: content.slug,
          categoryId: store.categoryIdOf(content.id),
          description: content.description,
          updatedAt: store.updatedAtOf(content.id),
        ),
    ];

    if (categoryId != null) {
      summaries = summaries
          .where((content) => content.categoryId == categoryId)
          .toList();
    }
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      summaries = summaries
          .where(
            (content) => content.name.toLowerCase().contains(normalizedQuery),
          )
          .toList();
    }

    summaries.sort((a, b) {
      final comparison = switch (sort) {
        ContentSort.updatedAt => a.updatedAt.compareTo(b.updatedAt),
        ContentSort.createdAt => a.updatedAt.compareTo(b.updatedAt),
        ContentSort.name => a.name.compareTo(b.name),
      };
      return order == ContentSortOrder.desc ? -comparison : comparison;
    });

    // No contrato real, trocar sort/order/q/categoryId invalida o cursor.
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final page = summaries.skip(startIndex).take(limit).toList();
    final endIndex = startIndex + page.length;
    final nextCursor = endIndex < summaries.length ? '$endIndex' : null;

    return Right(ContentsPage(items: page, nextCursor: nextCursor));
  }

  @override
  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  }) async {
    await Future<void>.delayed(_latency);
    if (store.slugExists(slug)) {
      return Left(
        ConflictFailure(suggestedSlug: SlugUtil.suggestFree(slug, store.slugs)),
      );
    }
    final content = store.create(
      name: name,
      slug: slug,
      description: description,
      categoryId: categoryId,
    );
    return Right(
      ContentSummary(
        id: content.id,
        name: content.name,
        slug: content.slug,
        categoryId: store.categoryIdOf(content.id),
        description: content.description,
        updatedAt: store.updatedAtOf(content.id),
      ),
    );
  }

  @override
  Future<Either<Failure, ContentSummary>> updateContent(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? categoryId,
  }) async {
    await Future<void>.delayed(_latency);
    final current = store.find(id);
    if (current == null) return const Left(NotFoundFailure());
    if (slug != null && slug != current.slug && store.slugExists(slug)) {
      return Left(
        ConflictFailure(suggestedSlug: SlugUtil.suggestFree(slug, store.slugs)),
      );
    }
    final updated = current.copyWith(
      name: name,
      slug: slug,
      description: description,
    );
    store.save(updated);
    if (categoryId != null) store.moveToCategory(id, categoryId);
    return Right(
      ContentSummary(
        id: updated.id,
        name: updated.name,
        slug: updated.slug,
        categoryId: store.categoryIdOf(updated.id),
        description: updated.description,
        updatedAt: store.updatedAtOf(updated.id),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteContent(String id) async {
    await Future<void>.delayed(_latency);
    if (!store.delete(id)) return const Left(NotFoundFailure());
    return const Right(unit);
  }
}
