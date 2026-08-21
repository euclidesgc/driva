import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/node_drag_feedback.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/selectable_node_surface.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// `expanded`/`spacer` só viram widgets `Expanded`/`Spacer` de verdade quando
/// o pai é um `Row`/`Column` (`buildExpanded`/`buildSpacer` do `sdui_flutter`
/// degradam para o filho puro fora disso, porque `Expanded` é um
/// `ParentDataWidget` e derruba a árvore sem um `Flex` direto). Interpor o
/// `Stack` do overlay entre eles e o `Flex` teria o mesmo efeito — por isso o
/// embrulho só é pulado quando `built` é de fato um `Expanded`/`Spacer`; fora
/// do flex (o caso que a marcação de erro precisa alcançar) o nó é
/// selecionável e recebe a mesma pele dos demais.
class SelectableNode extends StatelessWidget {
  const SelectableNode({
    required this.node,
    required this.built,
    required this.isSelected,
    required this.isHovered,
    required this.diagnostics,
    required this.onSelect,
    required this.onHover,
    required this.onAccept,
    this.isDraggable = true,
    super.key,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final List<SpecDiagnostic> diagnostics;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;
  final ValueChanged<DragPayload> onAccept;

  /// Falso enquanto o rascunho está congelado: o nó continua selecionável e
  /// com a mesma pele — mover é edição, selecionar para ler o diff não é.
  final bool isDraggable;

  bool get _isRawFlexParentDataWidget => switch (node.type) {
    'expanded' => built is Expanded,
    'spacer' => built is Spacer,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    if (_isRawFlexParentDataWidget) return built;

    final label = descriptorFor(node.type)?.label ?? node.type;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Semantics(
          label: label,
          selected: isSelected,
          child: Draggable<DragPayload>(
            data: NodeDragPayload(node.id),
            maxSimultaneousDrags: isDraggable ? 1 : 0,
            feedback: NodeDragFeedback(label: label),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: SelectableNodeSurface(
                label: label,
                built: built,
                isSelected: isSelected,
                isHovered: false,
                isDropTarget: false,
                diagnostics: diagnostics,
              ),
            ),
            child: DragTarget<DragPayload>(
              onWillAcceptWithDetails: (details) => switch (details.data) {
                NodeDragPayload(:final nodeId) => nodeId != node.id,
                PaletteDragPayload() => true,
              },
              onAcceptWithDetails: (details) => onAccept(details.data),
              builder: (context, candidates, _) => SelectableNodeSurface(
                label: label,
                built: built,
                isSelected: isSelected,
                isHovered: isHovered,
                isDropTarget: candidates.isNotEmpty,
                diagnostics: diagnostics,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
