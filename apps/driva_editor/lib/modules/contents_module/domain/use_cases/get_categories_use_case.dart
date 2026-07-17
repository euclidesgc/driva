import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/categories_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase({required this.repository});
  final CategoriesRepository repository;

  Future<Either<Failure, List<Category>>> call() => repository.getCategories();
}
