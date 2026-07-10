import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/category.dart';

/// Contrato do CRUD de categorias. O erro previsto mora na assinatura.
///
/// A árvore vem **flat** da API (lista de nós com `parentId`); montá-la em
/// árvore é derivação de quem consome (use case ou presentation), não deste
/// contrato.
abstract interface class CategoriesRepository {
  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? parentId,
  });

  /// Atualiza só os campos enviados: `name` renomeia, `parentId` move o nó
  /// para outro pai (`parentId` ausente preserva o pai atual).
  Future<Either<Failure, Category>> updateCategory(
    String id, {
    String? name,
    String? Function()? parentId,
  });

  Future<Either<Failure, Unit>> deleteCategory(String id);
}
