import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/content_summary.dart';
import '../repositories/contents_repository.dart';

class GetContentsUseCase {
  final ContentsRepository repository;
  const GetContentsUseCase({required this.repository});

  Future<Either<Failure, List<ContentSummary>>> call() async {
    final result = await repository.getContents();
    // Regra da listagem: mais recente primeiro. Roda só no caminho de sucesso.
    return result.map(
      (contents) => contents.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }
}
