import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/published_summary.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class PublishedSummaryModel extends PublishedSummary {
  const PublishedSummaryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.updatedAt,
  });

  static final ZMap _schema = z.map({
    'id': z.string().min(1),
    'name': z.string().min(1),
    'slug': z.string().min(1),
    'updatedAt': z.date(),
  });

  static Either<Failure, PublishedSummaryModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      PublishedSummaryModel(
        id: data['id'] as String,
        name: data['name'] as String,
        slug: data['slug'] as String,
        updatedAt: data['updatedAt'] as DateTime,
      ),
    );
  }
}
