import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/node_drag_feedback.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/selectable_node_surface.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// `spacer` e `expanded` não são envolvidos: os dois devolvem widgets que
/// precisam ser filhos diretos de Row/Column, e o `Stack` do overlay entre
/// eles e o `Flex` derruba o canvas com erro de `ParentDataWidget`. Sem
/// envelope eles também não arrastam pelo canvas — só pela árvore.
class SelectableNode extends StatelessWidget {
  const SelectableNode({
    required this.node,
    required this.built,
    required this.isSelected,
    required this.isHovered,
    required this.onSelect,
    required this.onHover,
    required this.onAccept,
    super.key,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;
  final ValueChanged<DragPayload> onAccept;

  static const _unwrappable = {'spacer', 'expanded'};

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

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
            maxSimultaneousDrags: 1,
            feedback: NodeDragFeedback(label: label),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: SelectableNodeSurface(
                label: label,
                built: built,
                isSelected: isSelected,
                isHovered: false,
                isDropTarget: false,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
