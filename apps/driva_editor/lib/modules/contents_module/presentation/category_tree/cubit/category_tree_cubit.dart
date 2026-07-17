import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

part 'category_tree_state.dart';

/// Seleção de nó e nós recolhidos são estado **local** desta tela (não
/// persistem entre sessões) — `null` selecionado é o pseudo-nó "Não
/// categorizados" (conteúdos sem `categoryId`).
class CategoryTreeCubit extends Cubit<CategoryTreeState> {
  CategoryTreeCubit({
    required this.getCategories,
    required this.createCategory,
    required this.updateCategory,
    required this.deleteCategory,
  }) : super(const CategoryTreeLoading());
  final GetCategoriesUseCase getCategories;
  final CreateCategoryUseCase createCategory;
  final UpdateCategoryUseCase updateCategory;
  final DeleteCategoryUseCase deleteCategory;

  Future<void> load() async {
    emit(const CategoryTreeLoading());
    final result = await getCategories();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => CategoryTreeError(failure: failure),
        (categories) => CategoryTreeLoaded(
          categories: categories,
          forest: CategoryNode.buildForest(categories),
          selectedCategoryId: null,
          collapsedIds: const {},
        ),
      ),
    );
  }

  void select(String? categoryId) {
    final current = state;
    if (current is! CategoryTreeLoaded) return;
    emit(current.copyWith(selectedCategoryId: () => categoryId));
  }

  void toggleCollapsed(String categoryId) {
    final current = state;
    if (current is! CategoryTreeLoaded) return;
    final collapsed = Set<String>.from(current.collapsedIds);
    if (!collapsed.add(categoryId)) collapsed.remove(categoryId);
    emit(current.copyWith(collapsedIds: collapsed));
  }

  Future<Either<Failure, Category>> create({
    required String name,
    String? parentId,
  }) async {
    final result = await createCategory(name: name, parentId: parentId);
    if (isClosed) return result;
    if (result.isRight()) await load();
    return result;
  }

  Future<Either<Failure, Category>> update(
    String id, {
    String? name,
    String? Function()? parentId,
  }) async {
    final result = await updateCategory(id, name: name, parentId: parentId);
    if (isClosed) return result;
    if (result.isRight()) await load();
    return result;
  }

  Future<Either<Failure, Unit>> delete(String id) async {
    final result = await deleteCategory(id);
    if (isClosed) return result;
    if (result.isRight()) {
      final current = state;
      final resetSelection =
          current is CategoryTreeLoaded && current.selectedCategoryId == id;
      await load();
      if (isClosed) return result;
      if (resetSelection) select(null);
    }
    return result;
  }

  /// Reflete um conteúdo movido entre categorias nos contadores da árvore,
  /// **in-place**: -1 na origem, +1 no destino, sem refetch, sem `Loading` e
  /// **sem resetar a seleção** — o usuário continua na categoria onde estava
  /// (mesmo que ela fique vazia). No-op fora do `Loaded` ou origem == destino.
  void applyContentMove({
    required String fromCategoryId,
    required String toCategoryId,
  }) {
    final current = state;
    if (current is! CategoryTreeLoaded || fromCategoryId == toCategoryId) {
      return;
    }
    final categories = [
      for (final c in current.categories)
        if (c.id == fromCategoryId)
          c.copyWith(contentCount: c.contentCount > 0 ? c.contentCount - 1 : 0)
        else if (c.id == toCategoryId)
          c.copyWith(contentCount: c.contentCount + 1)
        else
          c,
    ];
    emit(
      current.copyWith(
        categories: categories,
        forest: CategoryNode.buildForest(categories),
      ),
    );
  }
}
