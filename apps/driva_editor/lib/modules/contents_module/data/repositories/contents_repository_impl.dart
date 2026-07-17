import 'package:dio/dio.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/data/models/models.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_sort.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/contents_page.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/contents_repository.dart';
import 'package:fpdart/fpdart.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  ContentsRepositoryImpl(this.dio);
  final Dio dio;

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
  Future<Either<Failure, ContentSummary>> updateContent(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? categoryId,
  }) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/v1/contents/$id',
        data: {
          'name': ?name,
          'slug': ?slug,
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

  String _sortParam(ContentSort sort) => sort.name;
  String _orderParam(ContentSortOrder order) => order.name;

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

  String? _suggestedSlugFrom(dynamic body) {
    if (body is Map && body['suggestedSlug'] is String) {
      return body['suggestedSlug'] as String;
    }
    return null;
  }

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
