import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/page_summary.dart';
import '../repositories/pages_repository.dart';

class CreatePageUseCase {
  final PagesRepository repository;
  const CreatePageUseCase({required this.repository});

  Future<Either<Failure, PageSummary>> call({
    required String name,
    required String screenTarget,
  }) {
    final trimmedName = name.trim();
    final trimmedTarget = screenTarget.trim();
    if (trimmedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('O nome da página é obrigatório.')),
      );
    }
    if (trimmedTarget.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('A tela de destino é obrigatória.')),
      );
    }
    return repository.createPage(
      name: trimmedName,
      screenTarget: trimmedTarget,
    );
  }
}
