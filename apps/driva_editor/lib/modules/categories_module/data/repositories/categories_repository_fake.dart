import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';

/// Mesma interface, fonte em memória (dev/E2E sem backend). Um fake honra o
/// contrato de verdade: latência simulada, 409 de `Restrict` (categoria com
/// filhos/conteúdos) e erros previstos. Nasce com uma árvore pequena de
/// exemplo — "Geral" (raiz, como a seed do backend) com duas subcategorias.
class CategoriesRepositoryFake implements CategoriesRepository {
  static const _latency = Duration(milliseconds: 300);
  static const _generalId = 'cat_geral';

  final Map<String, Category> _categories = {
    _generalId: Category(
      id: _generalId,
      projectId: 'default',
      name: 'Geral',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    'cat_promocoes': Category(
      id: 'cat_promocoes',
      projectId: 'default',
      name: 'Promoções',
      parentId: _generalId,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    'cat_institucional': Category(
      id: 'cat_institucional',
      projectId: 'default',
      name: 'Institucional',
      parentId: _generalId,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  };
  int _sequence = 1;

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    await Future<void>.delayed(_latency);
    final categories = _categories.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Right(categories);
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
    final now = DateTime.now();
    final category = Category(
      id: id,
      projectId: 'default',
      name: name,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    _categories[id] = category;
    return Right(category);
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
    final updated = current.copyWith(
      name: name,
      updatedAt: DateTime.now(),
      parentId: parentId,
    );
    _categories[id] = updated;
    return Right(updated);
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
