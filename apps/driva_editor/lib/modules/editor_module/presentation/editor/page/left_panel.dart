import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

class LeftPanel extends StatefulWidget {
  const LeftPanel({super.key});

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  // Nasce aqui, não desce do EditorWorkspace: só assim o `const LeftPanel()`
  // continua curto-circuitando o rebuild do painel a cada `emit` (D28).
  final ValueNotifier<Set<String>> _collapsedCategories = ValueNotifier({});

  @override
  void dispose() {
    _collapsedCategories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;
    return ColoredBox(
      color: colors.panel,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Widgets', height: 40),
                Tab(text: 'Árvore', height: 40),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  WidgetPalettePanel(
                    collapsedCategories: _collapsedCategories,
                  ),
                  BlocSelector<EditorCubit, EditorState, String>(
                    selector: (state) {
                      if (state is! EditorReady) return '';
                      final root = state.document.root;
                      final structure = root == null ? '' : _structureKey(root);
                      return '$structure#${state.selectedNodeId ?? ''}';
                    },
                    builder: (context, _) {
                      final state = cubit.state;
                      if (state is! EditorReady) {
                        return const SizedBox.shrink();
                      }
                      return WidgetTreePanel(
                        root: state.document.root,
                        selectedNodeId: state.selectedNodeId,
                        nodeDiagnostics: diagnosticsByNode(state.diagnostics),
                        onSelect: cubit.selectNode,
                        onRemove: cubit.removeNode,
                        onDropNew: (type, targetId) =>
                            cubit.addNode(type, targetId: targetId),
                        onDropMove: cubit.moveNode,
                        onDropNewAt: cubit.addNodeAt,
                        onDropMoveAt: cubit.moveNodeAt,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
