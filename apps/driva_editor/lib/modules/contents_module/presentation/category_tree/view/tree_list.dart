import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/view/category_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TreeList extends StatelessWidget {
  const TreeList({
    required this.state,
    required this.allContentsCount,
    required this.contentCountByCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onMoveContent,
    super.key,
  });

  final CategoryTreeLoaded state;
  final int? allContentsCount;
  final Map<String, int> contentCountByCategory;
  final ValueChanged<Category> onEditCategory;
  final ValueChanged<Category> onDeleteCategory;
  final void Function(ContentSummary content, String categoryId) onMoveContent;

  @override
  Widget build(BuildContext context) {
    final flat = CategoryNode.flatten(
      state.forest,
      collapsedIds: state.collapsedIds,
    );
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      children: [
        CategoryRow(
          label: 'Todos os conteúdos',
          icon: Icons.apps_outlined,
          depth: 0,
          hasChildren: false,
          collapsed: false,
          count: allContentsCount,
          selected: state.selectedCategoryId == null,
          onSelect: () => context.read<CategoryTreeCubit>().select(null),
          onToggle: null,
          isAllContentsShortcut: true,
          onAcceptContent: null,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s8,
          ),
          child: Divider(height: 1),
        ),
        for (final (node, depth) in flat)
          CategoryRow(
            label: node.name,
            icon: Icons.folder_outlined,
            depth: depth,
            hasChildren: node.children.isNotEmpty,
            collapsed: state.collapsedIds.contains(node.id),
            count: contentCountByCategory[node.id],
            selected: state.selectedCategoryId == node.id,
            onSelect: () => context.read<CategoryTreeCubit>().select(node.id),
            onToggle: node.children.isNotEmpty
                ? () =>
                      context.read<CategoryTreeCubit>().toggleCollapsed(node.id)
                : null,
            onEdit: () => onEditCategory(node.category),
            onDelete: () => onDeleteCategory(node.category),
            onAcceptContent: (content) => onMoveContent(content, node.id),
          ),
      ],
    );
  }
}
