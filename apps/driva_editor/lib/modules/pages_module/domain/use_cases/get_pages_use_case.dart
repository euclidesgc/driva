import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/page_summary.dart';
import '../repositories/pages_repository.dart';

class GetPagesUseCase {
  final PagesRepository repository;
  const GetPagesUseCase({required this.repository});

  Future<Either<Failure, List<PageSummary>>> call() async {
    final result = await repository.getPages();
    // Regra da listagem: mais recente primeiro. Roda só no caminho de sucesso.
    return result.map(
      (pages) =>
          pages.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }
}
