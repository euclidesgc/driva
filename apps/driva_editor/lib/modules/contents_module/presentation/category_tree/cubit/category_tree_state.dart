part of 'category_tree_cubit.dart';

sealed class CategoryTreeState extends Equatable {
  const CategoryTreeState();
  @override
  List<Object?> get props => [];
}

final class CategoryTreeLoading extends CategoryTreeState {
  const CategoryTreeLoading();
}

final class CategoryTreeLoaded extends CategoryTreeState {
  const CategoryTreeLoaded({
    required this.categories,
    required this.forest,
    required this.selectedCategoryId,
    required this.collapsedIds,
  });

  /// Lista flat, como veio da API — fonte de verdade para lookups (ex.:
  /// resolver o nome da categoria selecionada) sem recorrer à árvore.
  final List<Category> categories;

  final List<CategoryNode> forest;

  /// `null` é o pseudo-nó "Não categorizados".
  final String? selectedCategoryId;

  final Set<String> collapsedIds;

  CategoryTreeLoaded copyWith({
    List<Category>? categories,
    List<CategoryNode>? forest,
    String? Function()? selectedCategoryId,
    Set<String>? collapsedIds,
  }) {
    return CategoryTreeLoaded(
      categories: categories ?? this.categories,
      forest: forest ?? this.forest,
      selectedCategoryId: selectedCategoryId != null
          ? selectedCategoryId()
          : this.selectedCategoryId,
      collapsedIds: collapsedIds ?? this.collapsedIds,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    forest,
    selectedCategoryId,
    collapsedIds,
  ];
}

final class CategoryTreeError extends CategoryTreeState {
  final Failure failure;
  const CategoryTreeError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
