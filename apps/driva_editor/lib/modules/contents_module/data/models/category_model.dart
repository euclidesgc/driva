import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.projectId,
    required super.name,
    required super.contentCount,
    super.parentId,
  });

  // A forma esperada do item de `GET /v1/categories` e do detalhe
  // (`POST`/`PUT /v1/categories/:id`), declarada uma vez. O backend também
  // manda `slug`/timestamps, mas o editor não os usa hoje — z.map descarta
  // chaves sem schema próprio, então ficam de fora sem quebrar o parse.
  static final ZMap _schema = z.map({
    'id': z.string().min(1),
    'projectId': z.string().min(1),
    'name': z.string().min(1),
    'parentId': z.string().nullable().optional(),
    'contentCount': z.int(),
  });

  static Either<Failure, CategoryModel> tryParse(Map<String, dynamic> map) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      CategoryModel(
        id: data['id'] as String,
        projectId: data['projectId'] as String,
        name: data['name'] as String,
        parentId: data['parentId'] as String?,
        contentCount: data['contentCount'] as int,
      ),
    );
  }
}
