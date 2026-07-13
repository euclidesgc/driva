import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/editor_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/content_summary.dart';
import 'category_node.dart';
import 'cubit/category_tree_cubit.dart';

/// Árvore de categorias do painel esquerdo da tela do projeto: "Todos os
/// conteúdos" fixo no topo (pseudo-nó `categoryId: null` — filtro "ver
/// tudo", não uma categoria), divisor, depois a árvore recursiva por
/// `parentId` com indentação, contador e ações de hover (editar/excluir).
///
/// Todo conteúdo tem `categoryId` obrigatório (default "Geral", semeada pelo
/// backend) — não existe conteúdo "sem categoria". O pseudo-nó do topo é
/// puramente um atalho de navegação para o projeto inteiro, por isso ganha
/// ícone e estilo distintos das categorias reais abaixo dele.
class CategoryTreeView extends StatelessWidget {
  const CategoryTreeView({
    super.key,
    required this.contentCountByCategory,
    required this.allContentsCount,
    required this.onNewCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onMoveContent,
  });

  /// Contagem de conteúdos por `categoryId` — a UI não inventa zero quando a
  /// contagem não foi carregada ainda (mostra vazio nesse caso).
  final Map<String, int> contentCountByCategory;

  /// Total de conteúdos do projeto (soma de todas as categorias) para o
  /// pseudo-nó "Todos os conteúdos". `null` enquanto não carregado — a UI
  /// não inventa zero.
  final int? allContentsCount;
  final VoidCallback onNewCategory;
  final ValueChanged<Category> onEditCategory;
  final ValueChanged<Category> onDeleteCategory;

  /// Soltar um conteúdo arrastado (feature 10, fase 3) sobre uma categoria
  /// real. O pseudo-nó "Todos os conteúdos" nunca chama isto — não é alvo de
  /// drop.
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
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 6),
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
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  final CategoryTreeError s => _TreeError(
                    failure: s.failure,
                    onRetry: () => context.read<CategoryTreeCubit>().load(),
                  ),
                  final CategoryTreeLoaded s => _TreeList(
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

class _TreeError extends StatelessWidget {
  const _TreeError({required this.failure, required this.onRetry});

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar as categorias.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeList extends StatelessWidget {
  const _TreeList({
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
        _CategoryRow(
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
          _CategoryRow(
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

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.depth,
    required this.hasChildren,
    required this.collapsed,
    required this.count,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.isAllContentsShortcut = false,
    required this.onAcceptContent,
  });

  final String label;
  final IconData icon;
  final int depth;
  final bool hasChildren;
  final bool collapsed;
  final int? count;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// `true` só para o pseudo-nó "Todos os conteúdos": não é uma categoria
  /// real, é um atalho de filtro. Ganha tratamento visual distinto (peso de
  /// fonte sempre marcado, sem contador tabular) para não ser confundido com
  /// irmão de "Geral" e demais categorias.
  final bool isAllContentsShortcut;

  /// Soltar um conteúdo arrastado sobre esta linha (feature 10, fase 3).
  /// `null` para o pseudo-nó "Todos os conteúdos": ele não vira
  /// `DragTarget`, nunca é alvo de drop.
  final ValueChanged<ContentSummary>? onAcceptContent;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final theme = Theme.of(context);

    if (widget.onAcceptContent != null) {
      return DragTarget<ContentSummary>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => widget.onAcceptContent!(details.data),
        builder: (context, candidateData, rejectedData) {
          return _buildRow(
            context,
            colors,
            theme,
            isDropTarget: candidateData.isNotEmpty,
          );
        },
      );
    }
    return _buildRow(context, colors, theme, isDropTarget: false);
  }

  Widget _buildRow(
    BuildContext context,
    EditorColors colors,
    ThemeData theme, {
    required bool isDropTarget,
  }) {
    // A cor nunca é o único sinal de seleção/highlight: o nó ativo (ou o
    // alvo do drop) também ganha um contorno (accent) — não só a tinta de
    // fundo.
    final highlighted = widget.selected || isDropTarget;
    final row = Container(
      margin: EdgeInsets.only(left: widget.depth * 16.0, bottom: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primaryTint
            : (_hovered ? colors.panelAlt : Colors.transparent),
        borderRadius: BorderRadius.circular(9),
        border: highlighted
            ? Border.all(color: theme.colorScheme.primary, width: 1)
            : null,
      ),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: widget.onToggle != null
                ? Tooltip(
                    message: widget.collapsed ? 'Expandir' : 'Recolher',
                    child: InkWell(
                      onTap: widget.onToggle,
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        widget.collapsed
                            ? Icons.chevron_right
                            : Icons.expand_more,
                        size: 16,
                        color: colors.inkMuted,
                      ),
                    ),
                  )
                : null,
          ),
          Icon(
            widget.icon,
            size: 16,
            color: highlighted ? theme.colorScheme.primary : colors.inkMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: highlighted || widget.isAllContentsShortcut
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: highlighted
                    ? theme.colorScheme.primary
                    : colors.inkPrimary,
              ),
            ),
          ),
          if (_hovered &&
              (widget.onEdit != null || widget.onDelete != null)) ...[
            if (widget.onEdit != null)
              _RowIconButton(
                tooltip: 'Editar categoria ${widget.label}',
                icon: Icons.edit_outlined,
                onPressed: widget.onEdit!,
              ),
            if (widget.onDelete != null)
              _RowIconButton(
                tooltip: 'Excluir categoria ${widget.label}',
                icon: Icons.delete_outline,
                onPressed: widget.onDelete!,
              ),
          ] else if (widget.count != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '${widget.count}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.isAllContentsShortcut
            ? '${widget.label}, ver todos os conteúdos do projeto'
                  '${widget.count != null ? ', ${widget.count} conteúdos' : ''}'
            : (widget.count != null
                  ? '${widget.label}, ${widget.count} conteúdos'
                  : widget.label),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(9),
          child: row,
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: colors.inkMuted),
        ),
      ),
    );
  }
}
