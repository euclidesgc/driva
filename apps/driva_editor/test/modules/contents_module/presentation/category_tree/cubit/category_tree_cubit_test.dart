import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCategories extends Mock implements GetCategoriesUseCase {}

class _MockCreateCategory extends Mock implements CreateCategoryUseCase {}

class _MockUpdateCategory extends Mock implements UpdateCategoryUseCase {}

class _MockDeleteCategory extends Mock implements DeleteCategoryUseCase {}

void main() {
  late _MockGetCategories getCategories;
  late _MockCreateCategory createCategory;
  late _MockUpdateCategory updateCategory;
  late _MockDeleteCategory deleteCategory;

  setUp(() {
    getCategories = _MockGetCategories();
    createCategory = _MockCreateCategory();
    updateCategory = _MockUpdateCategory();
    deleteCategory = _MockDeleteCategory();
  });

  CategoryTreeCubit build() => CategoryTreeCubit(
    getCategories: getCategories,
    createCategory: createCategory,
    updateCategory: updateCategory,
    deleteCategory: deleteCategory,
  );

  Category cat(
    String id,
    String name, {
    String? parentId,
    int contentCount = 0,
  }) => Category(
    id: id,
    projectId: 'p',
    name: name,
    parentId: parentId,
    contentCount: contentCount,
  );

  CategoryTreeLoaded loaded(
    List<Category> categories, {
    String? selectedCategoryId,
    Set<String> collapsedIds = const {},
  }) => CategoryTreeLoaded(
    categories: categories,
    forest: CategoryNode.buildForest(categories),
    selectedCategoryId: selectedCategoryId,
    collapsedIds: collapsedIds,
  );

  group('create (in-place, sem rebuild)', () {
    blocTest<CategoryTreeCubit, CategoryTreeState>(
      'adiciona o nó novo e reconstrói o forest, sem Loading nem refetch',
      build: build,
      seed: () => loaded([cat('a', 'Alfa')]),
      setUp: () => when(
        () => createCategory(name: 'Beta', parentId: null),
      ).thenAnswer((_) async => Right(cat('b', 'Beta'))),
      act: (cubit) => cubit.create(name: 'Beta'),
      expect: () => [
        loaded([cat('a', 'Alfa'), cat('b', 'Beta')]),
      ],
      verify: (_) => verifyNever(() => getCategories()),
    );
  });

  group('update (in-place)', () {
    blocTest<CategoryTreeCubit, CategoryTreeState>(
      'troca só o nó afetado (rename), preservando seleção/recolhidos',
      build: build,
      seed: () => loaded(
        [cat('a', 'Alfa'), cat('b', 'Beta')],
        selectedCategoryId: 'a',
        collapsedIds: {'b'},
      ),
      setUp: () => when(
        () => updateCategory('a', name: 'Alfa2', parentId: null),
      ).thenAnswer((_) async => Right(cat('a', 'Alfa2'))),
      act: (cubit) => cubit.update('a', name: 'Alfa2'),
      expect: () => [
        loaded(
          [cat('a', 'Alfa2'), cat('b', 'Beta')],
          selectedCategoryId: 'a',
          collapsedIds: {'b'},
        ),
      ],
      verify: (_) => verifyNever(() => getCategories()),
    );
  });

  group('delete (in-place)', () {
    blocTest<CategoryTreeCubit, CategoryTreeState>(
      'remove o nó e reseta a seleção quando era o selecionado',
      build: build,
      seed: () => loaded(
        [cat('a', 'Alfa'), cat('b', 'Beta')],
        selectedCategoryId: 'a',
        collapsedIds: {'a'},
      ),
      setUp: () => when(
        () => deleteCategory('a'),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.delete('a'),
      expect: () => [
        loaded([cat('b', 'Beta')]),
      ],
      verify: (_) => verifyNever(() => getCategories()),
    );

    blocTest<CategoryTreeCubit, CategoryTreeState>(
      'no erro (ex.: 409) não toca a árvore',
      build: build,
      seed: () => loaded([cat('a', 'Alfa')]),
      setUp: () => when(() => deleteCategory('a')).thenAnswer(
        (_) async => const Left(ConflictFailure(message: 'tem conteúdos')),
      ),
      act: (cubit) => cubit.delete('a'),
      expect: () => const <CategoryTreeState>[],
    );
  });
}
