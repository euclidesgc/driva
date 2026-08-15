import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/repositories/published_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetPublishedContentsUseCase {
  const GetPublishedContentsUseCase({required this.repository});

  final PublishedRepository repository;

  Future<Either<Failure, List<PublishedSummary>>> call() =>
      repository.getPublishedContents();
}
