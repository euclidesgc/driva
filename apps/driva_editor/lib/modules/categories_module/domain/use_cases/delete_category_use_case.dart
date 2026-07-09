import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/categories_repository.dart';

/// Passa-fica de propósito (Apêndice D do livro): a forma previsível vale o
/// boilerplate. O backend recusa (`Restrict` → `ConflictFailure`) apagar uma
/// categoria que ainda tem conteúdos.
class DeleteCategoryUseCase {
  final CategoriesRepository repository;
  const DeleteCategoryUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deleteCategory(id);
}
