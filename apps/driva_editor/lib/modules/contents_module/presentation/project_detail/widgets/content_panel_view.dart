import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/error.dart';
import '../../../../../core/theme/editor_colors.dart';
import '../../../../../core/util/date_format.dart';
import '../../../domain/entities/content_sort.dart';
import '../../../domain/entities/content_summary.dart';
import '../../content_list/cubit/content_list_cubit.dart';

enum ContentViewMode { grid, list }

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
    required this.onOpenContent,
    required this.onNewContent,
    required this.onEditContent,
    required this.onMoveContent,
    required this.onDeleteContent,
  });

  final String categoryLabel;
  final bool isAllContents;
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
                      hintText: 'Buscar conteúdo...',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SortControl(
                sort: _sort,
                order: _order,
                onSortChanged: _onSortFieldChanged,
                onToggleOrder: _onToggleOrder,
              ),
              const SizedBox(width: 10),
              _ViewModeToggle(
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
                ContentListEmpty() => _EmptyContents(
                  categoryLabel: widget.categoryLabel,
                  isAllContents: widget.isAllContents,
                  onCreate: widget.onNewContent,
                ),
                final ContentListError s => _PanelError(
                  failure: s.failure,
                  onRetry: () => context.read<ContentListCubit>().load(),
                ),
                final ContentListLoaded s => _ContentsCollection(
                  contents: s.contents,
                  mode: _mode,
                  hasMore: s.hasMore,
                  isLoadingMore: s.isLoadingMore,
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

class _PanelError extends StatelessWidget {
  const _PanelError({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
      NotFoundFailure() => 'Nada encontrado.',
      ConflictFailure(message: final m) => m,
      ValidationFailure(message: final m) => m,
      UnexpectedFailure() => 'Algo deu errado.',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}

/// Controle de ordenação: escolhe o campo (menu) e alterna a direção
/// (asc/desc). Toda mudança recarrega a lista pelo servidor (via cubit).
class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.sort,
    required this.order,
    required this.onSortChanged,
    required this.onToggleOrder,
  });

  final ContentSort sort;
  final ContentSortOrder order;
  final ValueChanged<ContentSort> onSortChanged;
  final VoidCallback onToggleOrder;

  static String _label(ContentSort sort) => switch (sort) {
    ContentSort.updatedAt => 'Atualização',
    ContentSort.createdAt => 'Criação',
    ContentSort.name => 'Nome',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final isDesc = order == ContentSortOrder.desc;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Ordenar por',
            child: PopupMenuButton<ContentSort>(
              initialValue: sort,
              onSelected: onSortChanged,
              tooltip: '',
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                for (final option in ContentSort.values)
                  CheckedPopupMenuItem<ContentSort>(
                    value: option,
                    checked: option == sort,
                    child: Text(_label(option)),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: colors.inkMuted),
                    const SizedBox(width: 6),
                    Text(
                      _label(sort),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Tooltip(
            message: isDesc ? 'Decrescente' : 'Crescente',
            child: Semantics(
              button: true,
              label:
                  'Direção da ordenação: '
                  '${isDesc ? 'decrescente' : 'crescente'}',
              child: InkWell(
                onTap: onToggleOrder,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 30,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    isDesc ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final ContentViewMode mode;
  final ValueChanged<ContentViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            tooltip: 'Grade',
            icon: Icons.grid_view_rounded,
            selected: mode == ContentViewMode.grid,
            onPressed: () => onChanged(ContentViewMode.grid),
          ),
          _ToggleButton(
            tooltip: 'Lista',
            icon: Icons.view_list_rounded,
            selected: mode == ContentViewMode.list,
            onPressed: () => onChanged(ContentViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 30,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primaryTint : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: selected
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? theme.colorScheme.primary : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentsCollection extends StatelessWidget {
  const _ContentsCollection({
    required this.contents,
    required this.mode,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final List<ContentSummary> contents;
  final ContentViewMode mode;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  /// Antecipa a próxima página ~1,5 tela antes do fim (rolagem sem "solavanco").
  static const _prefetchExtent = 400.0;

  bool _onScroll(ScrollNotification notification) {
    if (hasMore &&
        !isLoadingMore &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - _prefetchExtent) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Reserva espaço no rodapé para o loader não cobrir o último item.
    final bottomPadding = isLoadingMore ? 64.0 : 24.0;
    final Widget collection = mode == ContentViewMode.list
        ? ListView.separated(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
            itemCount: contents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ContentRow(
              content: contents[index],
              onOpen: onOpen,
              onEdit: onEdit,
              onMove: onMove,
              onDelete: onDelete,
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 300 / 150,
            ),
            itemCount: contents.length,
            itemBuilder: (context, index) => _ContentCard(
              content: contents[index],
              onOpen: onOpen,
              onEdit: onEdit,
              onMove: onMove,
              onDelete: onDelete,
            ),
          );

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          collection,
          if (isLoadingMore)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: _LoadingMoreFooter(),
            ),
        ],
      ),
    );
  }
}

/// Rodapé de "carregando mais" do scroll infinito (pílula com spinner + texto;
/// o texto garante que a informação não dependa só do movimento).
class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Carregando mais conteúdos',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Carregando mais…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  Widget _buildContent(BuildContext context, {double opacity = 1}) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: opacity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onOpen(content),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _SlugBadge(slug: content.slug)),
                    _CardActions(
                      content: content,
                      onEdit: onEdit,
                      onMove: onMove,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  content.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                _UpdatedAt(updatedAt: content.updatedAt),
                const SizedBox(height: 3),
                _SupportId(id: content.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DraggableContent(
      content: content,
      childWhenDragging: _buildContent(context, opacity: 0.4),
      child: _buildContent(context),
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.content,
    required this.onOpen,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onOpen;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  Widget _buildContent(BuildContext context, {double opacity = 1}) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: colors.panel,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => onOpen(content),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _SlugBadge(slug: content.slug),
                const SizedBox(width: 14),
                // Título com espaço generoso: na lista ele não espreme (só
                // trunca em telas realmente estreitas), diferente do card de
                // grade que reserva espaço fixo para as ações.
                Expanded(
                  child: Text(
                    content.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _UpdatedAt(updatedAt: content.updatedAt),
                const SizedBox(width: 6),
                _CardActions(
                  content: content,
                  onEdit: onEdit,
                  onMove: onMove,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DraggableContent(
      content: content,
      childWhenDragging: _buildContent(context, opacity: 0.4),
      child: _buildContent(context),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.content,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final ContentSummary content;
  final ValueChanged<ContentSummary> onEdit;
  final ValueChanged<ContentSummary> onMove;
  final ValueChanged<ContentSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Editar conteúdo',
          child: InkWell(
            onTap: () => onEdit(content),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.edit_outlined,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Mover conteúdo para outra categoria',
          child: InkWell(
            onTap: () => onMove(content),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.drive_file_move_outline,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Excluir conteúdo',
          child: InkWell(
            onTap: () => onDelete(content),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 15,
                color: colors.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slug em destaque: ícone + rótulo textual "slug" (a cor não é o único
/// sinal).
class _SlugBadge extends StatelessWidget {
  const _SlugBadge({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Slug do conteúdo: $slug',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                slug,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data da última modificação (`updatedAt`) — ícone de relógio + texto, para
/// que a informação não dependa só da cor. Fonte pequena e discreta; o valor
/// exato (fuso local) aparece formatado e como rótulo de acessibilidade.
class _UpdatedAt extends StatelessWidget {
  const _UpdatedAt({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final formatted = DateFormatUtil.dayMonthYearHourMinute(updatedAt);
    return Tooltip(
      message: 'Última modificação',
      child: Semantics(
        label: 'Modificado em $formatted',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: colors.inkMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                formatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportId extends StatelessWidget {
  const _SupportId({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'ID de suporte — use ao reportar um problema.',
      child: Semantics(
        label: 'ID de suporte: $id',
        child: Text(
          '# ID de suporte: $id',
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _EmptyContents extends StatelessWidget {
  const _EmptyContents({
    required this.categoryLabel,
    this.isAllContents = false,
    required this.onCreate,
  });

  final String categoryLabel;
  final bool isAllContents;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  size: 24,
                  color: Color(0xFFE8602C),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAllContents
                    ? 'Nenhum conteúdo neste projeto ainda'
                    : 'Nenhum conteúdo em "$categoryLabel"',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                isAllContents
                    ? 'Crie o primeiro conteúdo do projeto.'
                    : 'Crie o primeiro conteúdo desta categoria.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Novo conteúdo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Origem do drag-and-drop (feature 10, fase 2): embrulha o card/linha num
/// `Draggable<ContentSummary>` com chip de feedback compacto, origem
/// esmaecida enquanto arrasta e cursor "grab" + tooltip curta na origem.
///
/// O botão "mover" de [_CardActions] permanece como caminho acessível
/// primário — o drag é só um atalho, nunca o único sinal (D6/CA10).
class _DraggableContent extends StatelessWidget {
  const _DraggableContent({
    required this.content,
    required this.child,
    required this.childWhenDragging,
  });

  final ContentSummary content;
  final Widget child;
  final Widget childWhenDragging;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Arraste para mover de categoria',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Semantics(
          label: 'Conteúdo ${content.name}. Arraste para mover de categoria.',
          child: Draggable<ContentSummary>(
            data: content,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: FractionalTranslation(
              translation: const Offset(0.2, -1.15),
              child: _ContentDragChip(content: content),
            ),
            childWhenDragging: childWhenDragging,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Chip compacto que segue o cursor durante o arraste (D2): só o título,
/// embrulhado em `Material` para não perder o tema no overlay do drag.
class _ContentDragChip extends StatelessWidget {
  const _ContentDragChip({required this.content});

  final ContentSummary content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_indicator,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  content.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
