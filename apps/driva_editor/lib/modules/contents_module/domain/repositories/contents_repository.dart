import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/content_summary.dart';

/// Contrato da listagem/CRUD de conteúdos. O erro previsto mora na assinatura.
abstract interface class ContentsRepository {
  Future<Either<Failure, List<ContentSummary>>> getContents();

  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
  });

  Future<Either<Failure, Unit>> deleteContent(String id);
}
