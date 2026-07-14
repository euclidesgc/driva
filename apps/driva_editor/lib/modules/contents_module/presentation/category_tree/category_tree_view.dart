import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/content_summary.dart';
import 'cubit/category_tree_cubit.dart';
import 'view/view.dart';

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
