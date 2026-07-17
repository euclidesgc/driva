import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/categories_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteCategoryUseCase {
  const DeleteCategoryUseCase({required this.repository});
  final CategoriesRepository repository;

  Future<Either<Failure, Unit>> call(String id) =>
      repository.deleteCategory(id);
}
