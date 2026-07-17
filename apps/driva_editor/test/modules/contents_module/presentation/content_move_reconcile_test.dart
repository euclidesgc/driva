import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCategories extends Mock implements GetCategoriesUseCase {}

class _MockCreateCategory extends Mock implements CreateCategoryUseCase {}

class _MockUpdateCategory extends Mock implements UpdateCategoryUseCase {}

class _MockDeleteCategory extends Mock implements DeleteCategoryUseCase {}

class _MockGetContents extends Mock implements GetContentsUseCase {}

class _MockCreateContent extends Mock implements CreateContentUseCase {}

class _MockDeleteContent extends Mock implements DeleteContentUseCase {}

void main() {
  Category cat(String id, String name, {int contentCount = 0}) =>
      Category(id: id, projectId: 'p', name: name, contentCount: contentCount);

  CategoryTreeLoaded tree(
    List<Category> categories, {
    String? selectedCategoryId,
  }) => CategoryTreeLoaded(
    categories: categories,
    forest: CategoryNode.buildForest(categories),
    selectedCategoryId: selectedCategoryId,
    collapsedIds: const {},
  );

  ContentSummary content(String id, String categoryId) => ContentSummary(
    id: id,
    name: 'C$id',
    slug: 'c$id',
    categoryId: categoryId,
    updatedAt: DateTime.utc(2026, 7, 12),
  );

  group('CategoryTreeCubit.applyContentMove', () {
    blocTest<CategoryTreeCubit, CategoryTreeState>(
      '-1 na origem, +1 no destino, preservando a seleção (sem Loading)',
      build: () => CategoryTreeCubit(
        getCategories: _MockGetCategories(),
        createCategory: _MockCreateCategory(),
        updateCategory: _MockUpdateCategory(),
        deleteCategory: _MockDeleteCategory(),
      ),
      seed: () => tree([
        cat('geral', 'Geral', contentCount: 2),
        cat('home', 'Home'),
      ], selectedCategoryId: 'geral'),
      act: (cubit) =>
          cubit.applyContentMove(fromCategoryId: 'geral', toCategoryId: 'home'),
      expect: () => [
        tree([
          cat('geral', 'Geral', contentCount: 1),
          cat('home', 'Home', contentCount: 1),
        ], selectedCategoryId: 'geral'),
      ],
    );

    blocTest<CategoryTreeCubit, CategoryTreeState>(
      'origem == destino é no-op',
      build: () => CategoryTreeCubit(
        getCategories: _MockGetCategories(),
        createCategory: _MockCreateCategory(),
        updateCategory: _MockUpdateCategory(),
        deleteCategory: _MockDeleteCategory(),
      ),
      seed: () => tree([cat('geral', 'Geral', contentCount: 2)]),
      act: (cubit) => cubit.applyContentMove(
        fromCategoryId: 'geral',
        toCategoryId: 'geral',
      ),
      expect: () => const <CategoryTreeState>[],
    );
  });

  group('ContentListCubit.reflectMovedOut', () {
    ContentListCubit build({String? categoryId}) => ContentListCubit(
      getContents: _MockGetContents(),
      createContent: _MockCreateContent(),
      deleteContent: _MockDeleteContent(),
      categoryId: categoryId,
    );

    blocTest<ContentListCubit, ContentListState>(
      'remove o conteúdo movido da categoria filtrada (sem refetch)',
      build: () => build(categoryId: 'geral'),
      seed: () => ContentListLoaded(
        contents: [content('1', 'geral'), content('2', 'geral')],
      ),
      act: (cubit) => cubit.reflectMovedOut('1'),
      expect: () => [
        ContentListLoaded(contents: [content('2', 'geral')]),
      ],
    );

    blocTest<ContentListCubit, ContentListState>(
      'ao esvaziar a categoria filtrada, vira Empty',
      build: () => build(categoryId: 'geral'),
      seed: () => ContentListLoaded(contents: [content('1', 'geral')]),
      act: (cubit) => cubit.reflectMovedOut('1'),
      expect: () => [const ContentListEmpty()],
    );

    blocTest<ContentListCubit, ContentListState>(
      'na vista "Todos os conteúdos" (filtro null) não muda nada',
      build: build,
      seed: () => ContentListLoaded(contents: [content('1', 'geral')]),
      act: (cubit) => cubit.reflectMovedOut('1'),
      expect: () => const <ContentListState>[],
    );
  });
}
