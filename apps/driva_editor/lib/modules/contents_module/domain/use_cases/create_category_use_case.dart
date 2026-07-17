import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/categories_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateCategoryUseCase {
  const CreateCategoryUseCase({required this.repository});
  final CategoriesRepository repository;

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
