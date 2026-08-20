import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_checkpoint_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class ContentCheckpointsPageModel extends ContentCheckpointsPage {
  const ContentCheckpointsPageModel({required super.items, super.nextCursor});

  static final ZMap _schema = z.map({
    'data': z.list(z.map({})),
    'nextCursor': z.string().optional(),
  });

  static Either<Failure, ContentCheckpointsPageModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _schema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }

    // O conteúdo de cada item vem do `map` bruto: `z.list(z.map({}))` só
    // confirma a forma externa, como em `ContentVersionsPageModel`.
    final rows = (map['data'] as List).cast<Map<String, dynamic>>();
    final items = <ContentCheckpoint>[];
    for (final row in rows) {
      final parsed = ContentCheckpointModel.tryParse(row);
      final failure = parsed.getLeft().toNullable();
      if (failure != null) return Left(failure);
      items.add(parsed.getOrElse((_) => throw StateError('inalcançável')));
    }

    return Right(
      ContentCheckpointsPageModel(
        items: items,
        nextCursor: envelope.data!['nextCursor'] as String?,
      ),
    );
  }
}
