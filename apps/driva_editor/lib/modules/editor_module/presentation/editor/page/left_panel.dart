import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/editor_colors.dart';
import '../cubit/editor_cubit.dart';
import '../widgets/widget_palette_panel.dart';
import '../widgets/widget_tree_panel.dart';

/// Painel esquerdo: paleta (sem dependência de estado → construída uma vez) e
/// árvore (rebuilda só quando a ESTRUTURA ou a seleção mudam, não a cada tecla).
class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

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
                  const WidgetPalettePanel(),
                  BlocSelector<EditorCubit, EditorState, String>(
                    // Assinatura de estrutura + seleção: props não a alteram,
                    // então editar uma propriedade NÃO reconstrói a árvore.
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
                        onSelect: cubit.selectNode,
                        onRemove: cubit.removeNode,
                        onAddInto: (type, parentId, index) => cubit.addNode(
                          type,
                          parentId: parentId,
                          index: index,
                        ),
                        onMoveInto: cubit.moveNode,
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

/// Chave leve da estrutura da árvore (id + tipo + nº de filhos, recursivo).
/// Muda em inserção/remoção/movimento; NÃO muda ao editar props.
String _structureKey(SduiNode node) {
  final buffer = StringBuffer('${node.id}:${node.type}(');
  for (final child in node.children) {
    buffer.write(_structureKey(child));
    buffer.write(',');
  }
  buffer.write(')');
  return buffer.toString();
}
