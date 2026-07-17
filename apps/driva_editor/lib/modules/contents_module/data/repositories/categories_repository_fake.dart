import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/categories_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Um fake honra o
/// contrato de verdade: latência simulada, 409 de `Restrict` (categoria com
/// filhos/conteúdos) e erros previstos. Nasce com uma árvore pequena de
/// exemplo — "Geral" (raiz, como a seed do backend) com duas subcategorias.
///
/// [store] é o mesmo `FakeContentsStore` do `ContentsRepositoryFake` (os
/// dois repositórios vivem no mesmo módulo/camada `data`) — usado só para
/// computar `contentCount` real por categoria, espelhando o `_count` do
/// Prisma no backend (conteúdos DIRETOS, sem somar subcategorias).
class CategoriesRepositoryFake implements CategoriesRepository {
  CategoriesRepositoryFake(this.store);

  final FakeContentsStore store;

  static const _latency = Duration(milliseconds: 300);
  static const _generalId = 'cat_geral';

  // `Map` literal preserva ordem de inserção — usada como proxy de
  // "createdAt" já que a entidade não carrega timestamp (o backend não os
  // devolve para categoria). `contentCount` fica placeholder (0) aqui: quem
  // lê a contagem sempre passa pelo `_withCounts` abaixo.
  final Map<String, Category> _categories = {
    _generalId: const Category(
      id: _generalId,
      projectId: 'default',
      name: 'Geral',
      contentCount: 0,
    ),
    'cat_promocoes': const Category(
      id: 'cat_promocoes',
      projectId: 'default',
      name: 'Promoções',
      parentId: _generalId,
      contentCount: 0,
    ),
    'cat_institucional': const Category(
      id: 'cat_institucional',
      projectId: 'default',
      name: 'Institucional',
      parentId: _generalId,
      contentCount: 0,
    ),
  };
  int _sequence = 1;

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    await Future<void>.delayed(_latency);
    return Right(_categories.values.map(_withCount).toList());
  }

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? parentId,
  }) async {
    await Future<void>.delayed(_latency);
    if (parentId != null && !_categories.containsKey(parentId)) {
      return const Left(
        ValidationFailure('A categoria-pai informada não existe.'),
      );
    }
    final id = 'cat_fake_${_sequence++}';
    final category = Category(
      id: id,
      projectId: 'default',
      name: name,
      parentId: parentId,
      contentCount: 0,
    );
    _categories[id] = category;
    return Right(_withCount(category));
  }

  @override
  Future<Either<Failure, Category>> updateCategory(
    String id, {
    String? name,
    String? Function()? parentId,
  }) async {
    await Future<void>.delayed(_latency);
    final current = _categories[id];
    if (current == null) return const Left(NotFoundFailure());
    if (parentId != null) {
      final nextParentId = parentId();
      if (nextParentId != null && !_categories.containsKey(nextParentId)) {
        return const Left(
          ValidationFailure('A categoria-pai informada não existe.'),
        );
      }
    }
    final updated = current.copyWith(name: name, parentId: parentId);
    _categories[id] = updated;
    return Right(_withCount(updated));
  }

  /// Recalcula `contentCount` a partir do `store` compartilhado — os dois
  /// fakes (categorias e conteúdos) enxergam o mesmo estado, então mover ou
  /// criar/excluir conteúdo reflete na contagem sem estado duplicado.
  Category _withCount(Category category) {
    final count = store.contents
        .where((content) => store.categoryIdOf(content.id) == category.id)
        .length;
    return category.copyWith(contentCount: count);
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    await Future<void>.delayed(_latency);
    if (!_categories.containsKey(id)) return const Left(NotFoundFailure());
    // Espelha o `onDelete: Restrict` do backend: a "Geral" e qualquer
    // categoria com filhos são tratadas como "com conteúdos/subcategorias".
    final hasChildren = _categories.values.any((c) => c.parentId == id);
    if (id == _generalId || hasChildren) {
      return const Left(
        ConflictFailure(
          message:
              'Não é possível apagar uma categoria que ainda tem conteúdos '
              'ou subcategorias. Esvazie-a antes de apagá-la.',
        ),
      );
    }
    _categories.remove(id);
    return const Right(unit);
  }
}
