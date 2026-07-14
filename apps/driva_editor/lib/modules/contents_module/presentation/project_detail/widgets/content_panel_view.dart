import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/editor_colors.dart';
import '../../../domain/entities/content_sort.dart';
import '../../../domain/entities/content_summary.dart';
import '../../content_list/cubit/content_list_cubit.dart';
import 'content_panel/content_panel.dart';

/// O painel de conteúdos à direita da tela do projeto: busca com debounce,
/// alternância grade/lista e o `switch` exaustivo sobre `ContentListState`.
///
/// [categoryLabel]/[categoryCount] descrevem o nó selecionado na árvore (o
/// header "Home · 2 conteúdos" do `.dc.html`); [onOpenContent] navega ao
/// Construtor; [onNewContent]/[onEditContent]/[onDeleteContent] abrem os
/// formulários/confirmações (donos do modal ficam em `ProjectDetailPage`).
///
/// [isAllContents] indica que o filtro atual é o pseudo-nó "Todos os
/// conteúdos" (`categoryId: null`), não uma categoria real — muda a
/// mensagem do estado vazio.
class ContentPanelView extends StatefulWidget {
  const ContentPanelView({
    super.key,
    required this.categoryLabel,
    this.isAllContents = false,
    this.categoryNameById = const {},
    required this.onOpenContent,
    required this.onNewContent,
    required this.onEditContent,
    required this.onMoveContent,
    required this.onDeleteContent,
  });

  final String categoryLabel;
  final bool isAllContents;

  /// Nome de cada categoria (a "folha") por `id`, para o rótulo de categoria
  /// do card de grade. Vazio enquanto a árvore ainda carrega — o card omite
  /// a linha nesse caso.
  final Map<String, String> categoryNameById;
  final ValueChanged<ContentSummary> onOpenContent;
  final VoidCallback onNewContent;
  final ValueChanged<ContentSummary> onEditContent;
  final ValueChanged<ContentSummary> onMoveContent;
  final ValueChanged<ContentSummary> onDeleteContent;

  @override
  State<ContentPanelView> createState() => _ContentPanelViewState();
}

class _ContentPanelViewState extends State<ContentPanelView> {
  static const _debounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  ContentViewMode _mode = ContentViewMode.grid;

  /// Espelho local da ordenação (para exibir o controle); a fonte da verdade
  /// da query é o cubit, para onde empurramos toda mudança.
  late ContentSort _sort;
  late ContentSortOrder _order;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ContentListCubit>();
    _sort = cubit.currentSort;
    _order = cubit.currentOrder;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (!mounted) return;
      context.read<ContentListCubit>().reloadWithFilter(
        query: value.trim().isEmpty ? null : value.trim(),
      );
    });
  }

  void _onSortFieldChanged(ContentSort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    context.read<ContentListCubit>().changeSort(sort: sort);
  }

  void _onToggleOrder() {
    final next = _order == ContentSortOrder.desc
        ? ContentSortOrder.asc
        : ContentSortOrder.desc;
    setState(() => _order = next);
    context.read<ContentListCubit>().changeSort(order: next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    BlocBuilder<ContentListCubit, ContentListState>(
                      builder: (context, state) {
                        final count = switch (state) {
                          final ContentListLoaded s => s.contents.length,
                          _ => null,
                        };
                        return Text(
                          count == null
                              ? ' '
                              : '$count ${count == 1 ? 'conteúdo' : 'conteúdos'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 220,
                child: Semantics(
                  textField: true,
                  label: 'Buscar conteúdo',
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 18),
                      hintText: 'Buscar por nome, slug ou ID...',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SortControl(
                sort: _sort,
                order: _order,
                onSortChanged: _onSortFieldChanged,
                onToggleOrder: _onToggleOrder,
              ),
              const SizedBox(width: 10),
              ViewModeToggle(
                mode: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ContentListCubit, ContentListState>(
            builder: (context, state) {
              return switch (state) {
                ContentListLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ContentListEmpty() => EmptyContents(
                  categoryLabel: widget.categoryLabel,
                  isAllContents: widget.isAllContents,
                  onCreate: widget.onNewContent,
                ),
                final ContentListError s => PanelError(
                  failure: s.failure,
                  onRetry: () => context.read<ContentListCubit>().load(),
                ),
                final ContentListLoaded s => ContentsCollection(
                  contents: s.contents,
                  mode: _mode,
                  hasMore: s.hasMore,
                  isLoadingMore: s.isLoadingMore,
                  categoryNameById: widget.categoryNameById,
                  onLoadMore: () => context.read<ContentListCubit>().loadMore(),
                  onOpen: widget.onOpenContent,
                  onEdit: widget.onEditContent,
                  onMove: widget.onMoveContent,
                  onDelete: widget.onDeleteContent,
                ),
              };
            },
          ),
        ),
      ],
    );
  }
}
