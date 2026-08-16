import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Existe só para que a barra lateral (faixa larga) e a gaveta (`compact`,
/// D21) usem o mesmo [CategoryTreeView], sem alteração — sem este widget, a
/// construção duplicaria nos dois lugares.
class CategoryTreePanel extends StatelessWidget {
  const CategoryTreePanel({
    required this.onNewCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onMoveContent,
    super.key,
  });

  final VoidCallback onNewCategory;
  final ValueChanged<Category> onEditCategory;
  final ValueChanged<Category> onDeleteCategory;
  final void Function(ContentSummary content, String categoryId) onMoveContent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryTreeCubit, CategoryTreeState>(
      builder: (context, treeState) {
        final categories = treeState is CategoryTreeLoaded
            ? treeState.categories
            : const <Category>[];
        return CategoryTreeView(
          contentCountByCategory: {
            for (final category in categories)
              category.id: category.contentCount,
          },
          allContentsCount: treeState is CategoryTreeLoaded
              ? categories.fold<int>(
                  0,
                  (sum, category) => sum + category.contentCount,
                )
              : null,
          onNewCategory: onNewCategory,
          onEditCategory: onEditCategory,
          onDeleteCategory: onDeleteCategory,
          onMoveContent: onMoveContent,
        );
      },
    );
  }
}
