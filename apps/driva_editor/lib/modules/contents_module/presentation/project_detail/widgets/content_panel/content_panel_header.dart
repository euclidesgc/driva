import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_sort.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/content_view_mode.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/drawer_toggle_button.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/sort_control.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/view_mode_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// O layout de faixa larga fica intocado quando [isCompact] é falso: D20 só
/// exige que a faixa compacta funcione, e reempilhar um cabeçalho que já
/// funciona no desktop arriscaria regressão sem necessidade.
class ContentPanelHeader extends StatelessWidget {
  const ContentPanelHeader({
    required this.categoryLabel,
    required this.isCompact,
    required this.showDrawerToggle,
    required this.searchController,
    required this.onSearchChanged,
    required this.sort,
    required this.order,
    required this.onSortChanged,
    required this.onToggleOrder,
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  final String categoryLabel;
  final bool isCompact;
  final bool showDrawerToggle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ContentSort sort;
  final ContentSortOrder order;
  final ValueChanged<ContentSort> onSortChanged;
  final VoidCallback onToggleOrder;
  final ContentViewMode mode;
  final ValueChanged<ContentViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;

    final titleAndCount = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
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
    );

    final searchField = Semantics(
      textField: true,
      label: 'Buscar conteúdo',
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search, size: AppIconSizes.s18),
          hintText: 'Buscar por nome, slug ou ID...',
        ),
      ),
    );

    final sortAndToggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SortControl(
          sort: sort,
          order: order,
          onSortChanged: onSortChanged,
          onToggleOrder: onToggleOrder,
        ),
        const SizedBox(width: AppSpacing.s10),
        ViewModeToggle(mode: mode, onChanged: onModeChanged),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s20,
        AppSpacing.s24,
        AppSpacing.none,
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (showDrawerToggle) ...[
                      const DrawerToggleButton(),
                      const SizedBox(width: AppSpacing.s8),
                    ],
                    Expanded(child: titleAndCount),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                searchField,
                const SizedBox(height: AppSpacing.s10),
                Align(alignment: Alignment.centerLeft, child: sortAndToggle),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleAndCount),
                SizedBox(
                  width: AppSizes.contentPanelSearchWidth,
                  child: searchField,
                ),
                const SizedBox(width: AppSpacing.s10),
                sortAndToggle,
              ],
            ),
    );
  }
}
