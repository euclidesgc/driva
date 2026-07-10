import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

/// Renomeia e/ou move (`parentId`) uma categoria. `parentId` ausente preserva
/// o pai atual; `parentId: () => null` move o nó para a raiz.
class UpdateCategoryUseCase {
  final CategoriesRepository repository;
  const UpdateCategoryUseCase({required this.repository});

  Future<Either<Failure, Category>> call(
    String id, {
    String? name,
    String? Function()? parentId,
  }) {
    final trimmedName = name?.trim();
    if (trimmedName != null) {
      if (trimmedName.isEmpty) {
        return Future.value(
          const Left(ValidationFailure('O nome da categoria é obrigatório.')),
        );
      }
      if (trimmedName.length > 120) {
        return Future.value(
          const Left(
            ValidationFailure(
              'O nome da categoria deve ter até 120 caracteres.',
            ),
          ),
        );
      }
    }
    return repository.updateCategory(id, name: trimmedName, parentId: parentId);
  }
}
