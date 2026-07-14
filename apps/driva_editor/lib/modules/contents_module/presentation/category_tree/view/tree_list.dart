import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/content_summary.dart';
import '../category_node.dart';
import '../cubit/category_tree_cubit.dart';
import 'category_row.dart';

class TreeList extends StatelessWidget {
  const TreeList({
    super.key,
    required this.state,
    required this.allContentsCount,
    required this.contentCountByCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onMoveContent,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
