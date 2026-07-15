import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/entities/contents_page.dart';
import 'content_summary_model.dart';

/// A forma do envelope (`data` é lista, `nextCursor` é string opaca ou
/// `null`) é validada aqui via zard. `z.map` descarta chaves sem schema
/// próprio no resultado — por isso cada item de `data` é revalidado, com o
/// map **bruto** do JSON (não o resultado stripped do zard), por
/// [ContentSummaryModel.tryParse]: o mesmo parser usado no `create`/`update`,
/// então a forma do item não se duplica.
class ContentsPageModel {
  const ContentsPageModel._();

  static final _envelopeSchema = z.map({
    'data': z.list(z.map({}).optional()),
    'nextCursor': z.string().nullable().optional(),
  });

  static Either<Failure, ContentsPage> tryParse(Map<String, dynamic> map) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }

    final rawData = (map['data'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final items = <ContentSummary>[];
    for (final rawItem in rawData) {
      final parsed = ContentSummaryModel.tryParse(rawItem);
      if (parsed.isLeft()) {
        return parsed.map((_) => const ContentsPage(items: []));
      }
      items.add(parsed.getRight().toNullable()!);
    }
    return Right(
      ContentsPage(
        items: items,
        nextCursor: envelope.data!['nextCursor'] as String?,
      ),
    );
  }
}
