import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/data/models/published_summary_model.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/published_summary.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

/// Envelope de `GET /v1/public/projects/:projectId/contents`. Cada item é
/// revalidado com o map bruto do JSON por [PublishedSummaryModel.tryParse],
/// porque `z.map` descarta chaves sem schema próprio no resultado.
class PublishedListModel {
  const PublishedListModel._();

  static final ZMap _envelopeSchema = z.map({
    'data': z.list(z.map({}).optional()),
  });

  static Either<Failure, List<PublishedSummary>> tryParse(
    Map<String, dynamic> map,
  ) {
    final envelope = _envelopeSchema.safeParse(map);
    if (!envelope.success) {
      return Left(ValidationFailure(z.prettifyError(envelope.error!)));
    }

    final rawData = (map['data'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final items = <PublishedSummary>[];
    for (final rawItem in rawData) {
      final parsed = PublishedSummaryModel.tryParse(rawItem);
      if (parsed.isLeft()) {
        return parsed.map((_) => const <PublishedSummary>[]);
      }
      items.add(parsed.getRight().toNullable()!);
    }
    return Right(items);
  }
}
