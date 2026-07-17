import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/view/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryTreeView extends StatelessWidget {
  const CategoryTreeView({
    required this.contentCountByCategory,
    required this.allContentsCount,
    required this.onNewCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onMoveContent,
    super.key,
  });

  final Map<String, int> contentCountByCategory;

  final int? allContentsCount;
  final VoidCallback onNewCategory;
  final ValueChanged<Category> onEditCategory;
  final ValueChanged<Category> onDeleteCategory;

  final void Function(ContentSummary content, String categoryId) onMoveContent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return ColoredBox(
      color: colors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s14,
              AppSpacing.s14,
              AppSpacing.s10,
              AppSpacing.s6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CATEGORIAS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.inkMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Nova categoria',
                  child: IconButton(
                    onPressed: onNewCategory,
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CategoryTreeCubit, CategoryTreeState>(
              builder: (context, state) {
                return switch (state) {
                  CategoryTreeLoading() => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  final CategoryTreeError s => TreeErrorView(
                    failure: s.failure,
                    onRetry: () => context.read<CategoryTreeCubit>().load(),
                  ),
                  final CategoryTreeLoaded s => TreeList(
                    state: s,
                    allContentsCount: allContentsCount,
                    contentCountByCategory: contentCountByCategory,
                    onEditCategory: onEditCategory,
                    onDeleteCategory: onDeleteCategory,
                    onMoveContent: onMoveContent,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
