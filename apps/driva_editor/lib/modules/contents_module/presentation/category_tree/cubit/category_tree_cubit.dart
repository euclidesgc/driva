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

  /// Em sucesso, some com o nó e — se ele era o selecionado — a seleção
  /// volta para "Todos os conteúdos". Em falha (ex.: 409 por ter
  /// conteúdos/subcategorias), a árvore não muda; a UI mostra a mensagem da
  /// `Failure`.
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
}
