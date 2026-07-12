import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/use_cases/use_cases.dart';
import '../category_node.dart';

part 'category_tree_state.dart';

/// A árvore de categorias do projeto (fonte para o painel esquerdo da tela
/// do projeto). Carrega a lista flat via [GetCategoriesUseCase] e monta a
/// árvore por `parentId` na presentation ([CategoryNode.buildForest]).
///
/// Seleção de nó e nós recolhidos são estado **local** desta tela (não
/// persistem entre sessões) — `null` selecionado é o pseudo-nó "Não
/// categorizados" (conteúdos sem `categoryId`).
class CategoryTreeCubit extends Cubit<CategoryTreeState> {
  final GetCategoriesUseCase getCategories;
  final CreateCategoryUseCase createCategory;
  final UpdateCategoryUseCase updateCategory;
  final DeleteCategoryUseCase deleteCategory;

  CategoryTreeCubit({
    required this.getCategories,
    required this.createCategory,
    required this.updateCategory,
    required this.deleteCategory,
  }) : super(const CategoryTreeLoading());

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

  /// Seleciona um nó (ou `null` para "Todos os conteúdos"). Puramente local —
  /// não recarrega a árvore; quem escuta a seleção (o painel de conteúdos)
  /// reage à mudança.
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

  /// Cria e insere o nó novo na árvore atual, reconstruindo o forest a partir
  /// da lista flat (o `buildForest` reordena por nome), sem `Loading` nem
  /// refetch. No erro, a árvore não muda (a UI trata pelo `Left`).
  Future<Either<Failure, Category>> create({
    required String name,
    String? parentId,
  }) async {
    final result = await createCategory(name: name, parentId: parentId);
    if (isClosed) return result;
    final current = state;
    if (result.isRight() && current is CategoryTreeLoaded) {
      final created = result.getRight().toNullable()!;
      emit(_withCategories(current, [...current.categories, created]));
    } else if (result.isRight()) {
      await load();
    }
    return result;
  }

  /// Renomeia/move e reflete só o nó afetado (troca na lista flat + rebuild do
  /// forest, que já lida com o reparent via `parentId`), sem `Loading` nem
  /// refetch.
  Future<Either<Failure, Category>> update(
    String id, {
    String? name,
    String? Function()? parentId,
  }) async {
    final result = await updateCategory(id, name: name, parentId: parentId);
    if (isClosed) return result;
    final current = state;
    if (result.isRight() && current is CategoryTreeLoaded) {
      final updated = result.getRight().toNullable()!;
      emit(
        _withCategories(current, [
          for (final c in current.categories) c.id == updated.id ? updated : c,
        ]),
      );
    } else if (result.isRight()) {
      await load();
    }
    return result;
  }

  /// Em sucesso, some com o nó (in-place) e — se ele era o selecionado — a
  /// seleção volta para "Todos os conteúdos". O delete só passa em nó folha
  /// sem conteúdos (o backend restringe → 409), então remover só aquele id da
  /// lista flat é seguro. Em falha, a árvore não muda; a UI mostra a `Failure`.
  Future<Either<Failure, Unit>> delete(String id) async {
    final result = await deleteCategory(id);
    if (isClosed) return result;
    final current = state;
    if (result.isRight() && current is CategoryTreeLoaded) {
      final categories = current.categories.where((c) => c.id != id).toList();
      final collapsed = current.collapsedIds.contains(id)
          ? (Set<String>.from(current.collapsedIds)..remove(id))
          : current.collapsedIds;
      emit(
        current.copyWith(
          categories: categories,
          forest: CategoryNode.buildForest(categories),
          collapsedIds: collapsed,
          selectedCategoryId: current.selectedCategoryId == id
              ? () => null
              : null,
        ),
      );
    } else if (result.isRight()) {
      await load();
    }
    return result;
  }

  /// Reemite o `Loaded` com uma nova lista flat + o forest reconstruído dela,
  /// preservando seleção e nós recolhidos.
  CategoryTreeLoaded _withCategories(
    CategoryTreeLoaded current,
    List<Category> categories,
  ) {
    return current.copyWith(
      categories: categories,
      forest: CategoryNode.buildForest(categories),
    );
  }
}
