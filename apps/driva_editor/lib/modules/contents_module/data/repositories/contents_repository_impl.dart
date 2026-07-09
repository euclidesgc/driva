import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/content_sort.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/entities/contents_page.dart';
import '../../domain/repositories/contents_repository.dart';
import '../models/models.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  final Dio dio;
  ContentsRepositoryImpl(this.dio); // o Dio compartilhado, injetado

  @override
  Future<Either<Failure, ContentsPage>> getContents({
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/contents',
        queryParameters: {
          'categoryId': ?categoryId,
          'q': ?query,
          'sort': _sortParam(sort),
          'order': _orderParam(order),
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      return ContentsPageModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/contents',
        data: {
          'name': name,
          'slug': slug,
          'description': ?description,
          'categoryId': ?categoryId,
        },
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

  // O contrato aceita literalmente os nomes do enum (`updatedAt`, `createdAt`,
  // `name` / `asc`, `desc`) — sem mapeamento extra, só o valor cru.
  String _sortParam(ContentSort sort) => sort.name;
  String _orderParam(ContentSortOrder order) => order.name;

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
      400 => switch (_messageFrom(e.response?.data)) {
        final String message => ValidationFailure(message),
        null => const ValidationFailure(),
      },
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

  /// Extrai uma mensagem de erro do corpo do 400, quando o backend a
  /// oferece (Nest/class-validator costuma mandar `message`). Ausente →
  /// mensagem default do `ValidationFailure`.
  String? _messageFrom(dynamic body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (body is Map && body['message'] is List) {
      final messages = body['message'] as List;
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return null;
  }
}
