import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_version_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

/// Mesmo padrão de `ContentsPageModel`: o envelope (`data`/`nextCursor`) é
/// validado aqui, e cada item é revalidado pelo parser próprio a partir do
/// map bruto do JSON — o `z.map` do envelope descarta chaves sem schema.
class ContentVersionsPageModel {
  const ContentVersionsPageModel._();

  static final ZMap _envelopeSchema = z.map({
    'data': z.list(z.map({}).optional()),
    'nextCursor': z.string().nullable().optional(),
  });

  static Either<Failure, ContentVersionsPage> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }

    final rawData = (map['data'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final items = <ContentVersion>[];
    for (final rawItem in rawData) {
      final parsed = ContentVersionModel.tryParse(rawItem);
      if (parsed.isLeft()) {
        return parsed.map((_) => const ContentVersionsPage(items: []));
      }
      items.add(parsed.getRight().toNullable()!);
    }
    return Right(
      ContentVersionsPage(
        items: items,
        nextCursor: envelope.data!['nextCursor'] as String?,
      ),
    );
  }
}
