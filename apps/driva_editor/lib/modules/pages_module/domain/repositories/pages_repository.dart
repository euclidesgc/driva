import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/page_summary.dart';

/// Contrato da listagem/CRUD de páginas. O erro previsto mora na assinatura.
abstract interface class PagesRepository {
  Future<Either<Failure, List<PageSummary>>> getPages();

  Future<Either<Failure, PageSummary>> createPage({
    required String name,
    required String screenTarget,
  });

  Future<Either<Failure, Unit>> deletePage(String id);
}
