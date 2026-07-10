import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class CreateCategoryUseCase {
  final CategoriesRepository repository;
  const CreateCategoryUseCase({required this.repository});

  Future<Either<Failure, Category>> call({
    required String name,
    String? parentId,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('O nome da categoria é obrigatório.')),
      );
    }
    if (trimmedName.length > 120) {
      return Future.value(
        const Left(
          ValidationFailure('O nome da categoria deve ter até 120 caracteres.'),
        ),
      );
    }
    return repository.createCategory(name: trimmedName, parentId: parentId);
  }
}
