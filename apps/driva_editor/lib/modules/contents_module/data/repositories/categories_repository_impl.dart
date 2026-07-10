import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../models/models.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final Dio dio;
  CategoriesRepositoryImpl(this.dio); // o Dio compartilhado, injetado

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final response = await dio.get<List<dynamic>>('/v1/categories');
      final raw = (response.data ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      final categories = <Category>[];
      for (final map in raw) {
        final parsed = CategoryModel.tryParse(map);
        if (parsed.isLeft()) {
          return parsed.map((_) => <Category>[]);
        }
        categories.add(parsed.getRight().toNullable()!);
      }
      return Right(categories);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? parentId,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/categories',
        data: {'name': name, 'parentId': ?parentId},
      );
      return CategoryModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(
    String id, {
    String? name,
    String? Function()? parentId,
  }) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/v1/categories/$id',
        data: {
          'name': ?name,
          if (parentId != null) 'parentId': parentId(),
        },
      );
      return CategoryModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    try {
      await dio.delete<void>('/v1/categories/$id');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  // O único try/catch do módulo mora nesta classe: HTTP vira Failure aqui.
  // O 409 aqui é o `onDelete: Restrict` do backend (categoria com conteúdos
  // ou filhos) — mensagem própria, sem `suggestedSlug` (específico de
  // conteúdo).
  Failure _failureFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      404 => const NotFoundFailure(),
      409 => const ConflictFailure(
        message:
            'Não é possível apagar uma categoria que ainda tem conteúdos ou '
            'subcategorias. Esvazie-a antes de apagá-la.',
      ),
      400 => switch (_messageFrom(e.response?.data)) {
        final String message => ValidationFailure(message),
        null => const ValidationFailure(),
      },
      _ => const UnexpectedFailure(),
    },
    _ => const UnexpectedFailure(),
  };

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
