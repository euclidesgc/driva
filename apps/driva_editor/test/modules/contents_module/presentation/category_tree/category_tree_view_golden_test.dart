import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_tree_view.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden.dart';

class MockCategoryTreeCubit extends MockCubit<CategoryTreeState>
    implements CategoryTreeCubit {}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  final categories = <Category>[
    const Category(
      id: 'cat_geral',
      projectId: 'p1',
      name: 'Geral',
      contentCount: 5,
    ),
    const Category(
      id: 'cat_mkt',
      projectId: 'p1',
      name: 'Marketing',
      contentCount: 2,
    ),
    const Category(
      id: 'cat_promo',
      projectId: 'p1',
      name: 'Promoções',
      contentCount: 3,
      parentId: 'cat_mkt',
    ),
  ];

  testWidgets('golden: árvore carregada (com subcategoria e seleção)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cubit = MockCategoryTreeCubit();
    whenListen(
      cubit,
      const Stream<CategoryTreeState>.empty(),
      initialState: CategoryTreeLoaded(
        categories: categories,
        forest: CategoryNode.buildForest(categories),
        selectedCategoryId: 'cat_geral',
        collapsedIds: const {},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<CategoryTreeCubit>.value(
            value: cubit,
            child: CategoryTreeView(
              contentCountByCategory: const {
                'cat_geral': 5,
                'cat_mkt': 2,
                'cat_promo': 3,
              },
              allContentsCount: 10,
              onNewCategory: () {},
              onEditCategory: (_) {},
              onDeleteCategory: (_) {},
              onMoveContent: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CategoryTreeView),
      matchesGoldenFile('goldens/category_tree_loaded.png'),
    );
  });
}
