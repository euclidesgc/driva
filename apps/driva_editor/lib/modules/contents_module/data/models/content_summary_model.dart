import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class ContentSummaryModel extends ContentSummary {
  const ContentSummaryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.categoryId,
    required super.updatedAt,
    super.description,
  });

  // A forma esperada do item de `GET /v1/contents` (dentro do envelope
  // `{ data, nextCursor }`) e do detalhe (`POST`/`PUT`), declarada uma vez.
  static final ZMap _schema = z.map({
    'id': z.string().min(1),
    'name': z.string().min(1),
    'slug': z.string().min(1),
    'categoryId': z.string().min(1),
    'description': z.string().optional(),
    'updatedAt': z.date(),
  });

  static Either<Failure, ContentSummaryModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      ContentSummaryModel(
        id: data['id'] as String,
        name: data['name'] as String,
        slug: data['slug'] as String,
        categoryId: data['categoryId'] as String,
        description: data['description'] as String?,
        updatedAt: data['updatedAt'] as DateTime,
      ),
    );
  }
}
