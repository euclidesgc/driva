import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/repositories/contents_repository.dart';
import '../models/models.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  final Dio dio;
  ContentsRepositoryImpl(this.dio); // o Dio compartilhado, injetado

  @override
  Future<Either<Failure, List<ContentSummary>>> getContents() async {
    try {
      final response = await dio.get<List<dynamic>>('/v1/contents');
      final raw = (response.data ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      final contents = <ContentSummary>[];
      for (final map in raw) {
        final parsed = ContentSummaryModel.tryParse(map);
        if (parsed.isLeft()) {
          return parsed.map((_) => <ContentSummary>[]);
        }
        contents.add(parsed.getRight().toNullable()!);
      }
      return Right(contents);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/contents',
        data: {'name': name, 'slug': slug, 'description': ?description},
      );
      return ContentSummaryModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteContent(String id) async {
    try {
      await dio.delete<void>('/v1/contents/$id');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  // O único try/catch do módulo mora nesta classe: HTTP vira Failure aqui.
  // A tradução do 409 (slug em uso) → ConflictFailure vive só aqui.
  Failure _failureFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      404 => const NotFoundFailure(),
      409 => ConflictFailure(
        suggestedSlug: _suggestedSlugFrom(e.response?.data),
      ),
      400 => const ValidationFailure(),
      _ => const UnexpectedFailure(),
    },
    _ => const UnexpectedFailure(),
  };

  /// Extrai um slug livre sugerido do corpo do 409, quando o backend o
  /// oferece. Ausente → `null` e a presentation sugere localmente.
  String? _suggestedSlugFrom(dynamic body) {
    if (body is Map && body['suggestedSlug'] is String) {
      return body['suggestedSlug'] as String;
    }
    return null;
  }
}
