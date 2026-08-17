import 'package:dio/dio.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_versions_page_model.dart';
import 'package:driva_editor/modules/editor_module/data/models/publication_state_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

class EditorRepositoryImpl implements EditorRepository {
  EditorRepositoryImpl(this.dio);
  final Dio dio;

  @override
  Future<Either<Failure, LoadedContent>> loadContent(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/v1/contents/$id');
      final body = response.data ?? const <String, dynamic>{};
      final spec = body['spec'];
      if (spec is! Map) {
        return const Left(ValidationFailure('Resposta sem o campo "spec".'));
      }
      // A única porta JSON → entidade é o kernel; aqui só traduzimos o erro.
      final parsedSpec = parseContentSpec(
        spec.cast<String, dynamic>(),
      ).mapLeft<Failure>((error) => ValidationFailure(error.message));
      final parsedPublication = PublicationStateModel.tryParse(body);

      return parsedSpec.flatMap(
        (spec) => parsedPublication.map(
          (publication) => LoadedContent(spec: spec, publication: publication),
        ),
      );
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveDraft(ContentSpec content) async {
    try {
      await dio.put<void>(
        '/v1/contents/${content.id}',
        data: {'name': content.name, 'spec': content.toJson()},
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, PublicationState>> publish(
    String id, {
    String? note,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/contents/$id/publish',
        data: {'note': ?note},
      );
      final body = response.data ?? const <String, dynamic>{};
      return PublicationStateModel.tryParse(body);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> unpublish(String id) async {
    try {
      await dio.post<void>('/v1/contents/$id/unpublish');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, ContentVersionsPage>> listVersions(
    String id, {
    String? cursor,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/contents/$id/versions',
        queryParameters: {'cursor': ?cursor},
      );
      final body = response.data ?? const <String, dynamic>{};
      return ContentVersionsPageModel.tryParse(body);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, ContentSpec>> restoreVersion(
    String id,
    int version,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/contents/$id/versions/$version/restore',
      );
      final body = response.data ?? const <String, dynamic>{};
      final spec = body['spec'];
      if (spec is! Map) {
        return const Left(ValidationFailure('Resposta sem o campo "spec".'));
      }
      return parseContentSpec(
        spec.cast<String, dynamic>(),
      ).mapLeft((error) => ValidationFailure(error.message));
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  Failure _failureFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      404 => const NotFoundFailure(),
      409 => const ConflictFailure(),
      400 => const ValidationFailure(),
      _ => const UnexpectedFailure(),
    },
    _ => const UnexpectedFailure(),
  };
}
