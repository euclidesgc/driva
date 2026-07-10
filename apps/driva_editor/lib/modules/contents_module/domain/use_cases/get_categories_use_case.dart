import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

/// Passa-fica de propósito (Apêndice D do livro): a forma previsível vale o
/// boilerplate. Devolve a lista **flat**; montar a árvore é derivação de quem
/// consome.
class GetCategoriesUseCase {
  final CategoriesRepository repository;
  const GetCategoriesUseCase({required this.repository});

  Future<Either<Failure, List<Category>>> call() => repository.getCategories();
}
