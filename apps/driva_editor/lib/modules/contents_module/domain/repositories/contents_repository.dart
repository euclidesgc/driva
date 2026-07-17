import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_sort.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/contents_page.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ContentsRepository {
  Future<Either<Failure, ContentsPage>> getContents({
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
    String? cursor,
    int limit = 20,
  });

  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  });

  Future<Either<Failure, ContentSummary>> updateContent(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? categoryId,
  });

  Future<Either<Failure, Unit>> deleteContent(String id);
}
