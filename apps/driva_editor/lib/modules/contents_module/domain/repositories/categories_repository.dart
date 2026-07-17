import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class CategoriesRepository {
  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? parentId,
  });

  Future<Either<Failure, Category>> updateCategory(
    String id, {
    String? name,
    String? Function()? parentId,
  });

  Future<Either<Failure, Unit>> deleteCategory(String id);
}
