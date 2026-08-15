import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PublishedRepository {
  Future<Either<Failure, List<PublishedSummary>>> getPublishedContents();

  Future<Either<Failure, PublishedContent>> getPublishedContent(String slug);
}
