import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/page_summary.dart';
import '../../domain/repositories/pages_repository.dart';
import '../models/models.dart';

class PagesRepositoryImpl implements PagesRepository {
  final Dio dio;
  PagesRepositoryImpl(this.dio); // o Dio compartilhado, injetado

  @override
  Future<Either<Failure, List<PageSummary>>> getPages() async {
    try {
      final response = await dio.get<List<dynamic>>('/v1/pages');
      final raw = (response.data ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      final pages = <PageSummary>[];
      for (final map in raw) {
        final parsed = PageSummaryModel.tryParse(map);
        if (parsed.isLeft()) {
          return parsed.map((_) => <PageSummary>[]);
        }
        pages.add(parsed.getRight().toNullable()!);
      }
      return Right(pages);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, PageSummary>> createPage({
    required String name,
    required String screenTarget,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/v1/pages',
        data: {'name': name, 'screenTarget': screenTarget},
      );
      return PageSummaryModel.tryParse(response.data ?? const {});
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePage(String id) async {
    try {
      await dio.delete<void>('/v1/pages/$id');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_failureFor(e));
    }
  }

  // O único try/catch do módulo mora nesta classe: HTTP vira Failure aqui.
  Failure _failureFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      404 => const NotFoundFailure(),
      400 => const ValidationFailure(),
      _ => const UnexpectedFailure(),
    },
    _ => const UnexpectedFailure(),
  };
}
