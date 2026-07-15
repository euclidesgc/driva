import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class GetCategoriesUseCase {
  final CategoriesRepository repository;
  const GetCategoriesUseCase({required this.repository});

  Future<Either<Failure, List<Category>>> call() => repository.getCategories();
}
