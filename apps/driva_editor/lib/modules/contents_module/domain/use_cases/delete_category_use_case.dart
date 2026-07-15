import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/categories_repository.dart';

class DeleteCategoryUseCase {
  final CategoriesRepository repository;
  const DeleteCategoryUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) =>
      repository.deleteCategory(id);
}
