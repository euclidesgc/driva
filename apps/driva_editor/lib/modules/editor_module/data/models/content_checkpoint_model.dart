import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class ContentCheckpointModel extends ContentCheckpoint {
  const ContentCheckpointModel({
    required super.id,
    required super.createdAt,
    super.note,
    super.createdBy,
  });

  static final ZMap _schema = z.map({
    'id': z.string(),
    'createdAt': z.date(),
    'note': z.string().optional(),
    'createdBy': z.string().optional(),
  });

  static Either<Failure, ContentCheckpointModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      ContentCheckpointModel(
        id: data['id'] as String,
        createdAt: data['createdAt'] as DateTime,
        note: data['note'] as String?,
        createdBy: data['createdBy'] as String?,
      ),
    );
  }
}
