import 'package:dio/dio.dart';
import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/data/models/models.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/repositories/published_repository.dart';
import 'package:fpdart/fpdart.dart';

const String _basePath = '/v1/public/contents';

class PublishedRepositoryImpl implements PublishedRepository {
  PublishedRepositoryImpl(this.dio);

  final Dio dio;

  @override
  Future<Either<Failure, List<PublishedSummary>>> getPublishedContents() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(_basePath);
      return PublishedListModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, PublishedContent>> getPublishedContent(
    String slug,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('$_basePath/$slug');
      return PublishedContentModel.tryParse(
        response.data ?? const {},
        etag: response.headers.value('etag'),
      );
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  Failure _failureFor(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      404 => const NotFoundFailure(),
      400 => const ValidationFailure(),
      _ => const NetworkFailure(),
    };
  }
}
