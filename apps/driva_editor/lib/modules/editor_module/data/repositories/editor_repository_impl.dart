import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../../domain/repositories/editor_repository.dart';

class EditorRepositoryImpl implements EditorRepository {
  final Dio dio;
  EditorRepositoryImpl(this.dio);

  @override
  Future<Either<Failure, PageSpec>> loadPage(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/v1/pages/$id');
      final body = response.data ?? const <String, dynamic>{};
      final spec = body['spec'];
      if (spec is! Map) {
        return const Left(ValidationFailure('Resposta sem o campo "spec".'));
      }
      // A única porta JSON → entidade é o kernel; aqui só traduzimos o erro.
      return parsePageSpec(spec.cast<String, dynamic>())
          .mapLeft((error) => ValidationFailure(error.message));
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(PageSpec page) async {
    try {
      await dio.put<void>(
        '/v1/pages/${page.id}',
        data: {'name': page.name, 'spec': page.toJson()},
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  Failure _failureFor(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          const NetworkFailure(),
        DioExceptionType.badResponse => switch (e.response?.statusCode) {
            404 => const NotFoundFailure(),
            400 => const ValidationFailure(),
            _ => const UnexpectedFailure(),
          },
        _ => const UnexpectedFailure(),
      };
}
