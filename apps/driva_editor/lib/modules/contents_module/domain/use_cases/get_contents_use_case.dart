import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/content_sort.dart';
import '../entities/contents_page.dart';
import '../repositories/contents_repository.dart';

/// Sem re-sort no cliente: conflita com o cursor do servidor.
class GetContentsUseCase {
  final ContentsRepository repository;
  const GetContentsUseCase({required this.repository});

  Future<Either<Failure, ContentsPage>> call({
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
    String? cursor,
    int limit = 20,
  }) {
    if (limit < 1 || limit > 100) {
      return Future.value(
        const Left(ValidationFailure('O limite deve estar entre 1 e 100.')),
      );
    }
    final trimmedQuery = query?.trim();
    return repository.getContents(
      categoryId: categoryId,
      query: (trimmedQuery?.isEmpty ?? true) ? null : trimmedQuery,
      sort: sort,
      order: order,
      cursor: cursor,
      limit: limit,
    );
  }
}
