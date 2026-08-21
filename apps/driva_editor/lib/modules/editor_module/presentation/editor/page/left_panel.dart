import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/compare_aware_widget_tree.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/panel_collapse_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

class LeftPanel extends StatefulWidget {
  const LeftPanel({super.key});

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel>
    with SingleTickerProviderStateMixin {
  // Lido uma vez: `LeftPanel` só existe montado dentro do `EditorLayoutScope`
  // que `EditorWorkspace` instala — colapsar o painel desmonta este `State`
  // por inteiro (é a faixa fina tomando o lugar dele), então não há cenário
  // em que a aba mude enquanto este `State` sobrevive fora de um novo mount.
  // `null` = sem `EditorLayoutScope` acima (ex. teste isolado do painel) —
  // mesma degradação do `PanelCollapseButton`: a aba não sincroniza com o
  // controller e o botão de recolher some, mas o painel continua funcional.
  late final EditorLayoutController? _layoutController = EditorLayoutScope.of(
    context,
  );

  /// Alimenta `WidgetPalettePanel` quando [_layoutController] é `null` — os
  /// grupos colapsados da paleta não sobrevivem além deste `State` nesse
  /// cenário isolado, mesmo papel do `_uncontrolledNotifier` do
  /// `ResizableSplitView`.
  final ValueNotifier<Set<String>> _fallbackCollapsedCategories = ValueNotifier(
    {},
  );

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: _layoutController?.value.leftPanelTab.index ?? 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_syncTabToController);
  }

  void _syncTabToController() {
    if (_tabController.indexIsChanging) return;
    _layoutController?.setLeftPanelTab(
      LeftPanelTab.values[_tabController.index],
    );
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_syncTabToController)
      ..dispose();
    _fallbackCollapsedCategories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;
    final layoutController = _layoutController;
    return ColoredBox(
      color: colors.panel,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Widgets', height: 40),
                    Tab(text: 'Árvore', height: 40),
                  ],
                ),
              ),
              PanelCollapseButton(
                icon: Icons.chevron_left,
                label: 'Recolher painel',
                onCollapse: layoutController?.collapseLeftPanel,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BlocSelector<EditorCubit, EditorState, bool>(
                  selector: (state) => state is EditorReady && state.isReadOnly,
                  builder: (context, isReadOnly) => WidgetPalettePanel(
                    collapsedCategories:
                        layoutController?.collapsedPaletteCategories ??
                        _fallbackCollapsedCategories,
                    isReadOnly: isReadOnly,
                  ),
                ),
                BlocSelector<EditorCubit, EditorState, String>(
                  selector: (state) {
                    if (state is! EditorReady) return '';
                    final root = state.document.root;
                    final structure = root == null ? '' : _structureKey(root);
                    return '$structure#${state.selectedNodeId ?? ''}'
                        '#${state.isReadOnly}';
                  },
                  builder: (context, _) {
                    final state = cubit.state;
                    if (state is! EditorReady) {
                      return const SizedBox.shrink();
                    }
                    // A chave de estrutura do selector acima não enxerga o
                    // diff: trocar a candidata não muda estrutura nem
                    // seleção, e a árvore ficaria com marcadores da versão
                    // anterior — daí o builder aninhado sobre o cubit do
                    // modo.
                    final compareCubit = VersionCompareModeScope.of(context);
                    if (compareCubit == null) {
                      return CompareAwareWidgetTree(
                        state: state,
                        cubit: cubit,
                      );
                    }
                    return BlocBuilder<
                      VersionCompareModeCubit,
                      VersionCompareModeState
                    >(
                      bloc: compareCubit,
                      builder: (context, compareState) =>
                          CompareAwareWidgetTree(
                            state: state,
                            cubit: cubit,
                            compareState: compareState,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _structureKey(SduiNode node) {
  final buffer = StringBuffer('${node.id}:${node.type}(');
  final child = node.child;
  if (child != null) {
    buffer
      ..write(_structureKey(child))
      ..write(',');
  }
  for (final each in node.children) {
    buffer
      ..write(_structureKey(each))
      ..write(',');
  }
  buffer.write(')');
  return buffer.toString();
}
