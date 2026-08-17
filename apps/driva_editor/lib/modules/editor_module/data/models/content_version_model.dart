import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class ContentVersionModel extends ContentVersion {
  const ContentVersionModel({
    required super.version,
    required super.createdAt,
    super.note,
    super.createdBy,
  });

  static final ZMap _schema = z.map({
    'version': z.int(),
    'createdAt': z.date(),
    'note': z.string().optional(),
    'createdBy': z.string().optional(),
  });

  static Either<Failure, ContentVersionModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      ContentVersionModel(
        version: data['version'] as int,
        createdAt: data['createdAt'] as DateTime,
        note: data['note'] as String?,
        createdBy: data['createdBy'] as String?,
      ),
    );
  }
}
