import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/page_summary.dart';

class PageSummaryModel extends PageSummary {
  const PageSummaryModel({
    required super.id,
    required super.name,
    required super.screenTarget,
    required super.updatedAt,
  });

  // A forma esperada do item de `GET /v1/pages`, declarada uma vez.
  static final _schema = z.map({
    'id': z.string().min(1),
    'name': z.string().min(1),
    'screenTarget': z.string().min(1),
    'updatedAt': z.date(),
  });

  /// Valida e converte. Payload inválido vira `ValidationFailure` descritiva,
  /// nunca um cast cru estourando.
  static Either<Failure, PageSummaryModel> tryParse(Map<String, dynamic> map) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      PageSummaryModel(
        id: data['id'] as String,
        name: data['name'] as String,
        screenTarget: data['screenTarget'] as String,
        updatedAt: data['updatedAt'] as DateTime,
      ),
    );
  }
}
