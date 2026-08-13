import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/core/widgets/painters/painters.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/node_tag.dart';
import 'package:flutter/material.dart';

/// A pele do nó no canvas: contorno de seleção/hover/alvo de drop e a etiqueta
/// com o rótulo. Separado do `SelectableNode` porque o `Draggable` precisa da
/// mesma pele em `child` e em `childWhenDragging`.
class SelectableNodeSurface extends StatelessWidget {
  const SelectableNodeSurface({
    required this.label,
    required this.built,
    required this.isSelected,
    required this.isHovered,
    required this.isDropTarget,
    super.key,
  });

  final String label;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final bool isDropTarget;

  static final Color _hoverColor = AppTheme.primary.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final mock = Theme.of(context).extension<DeviceMockColors>()!;
    return Stack(
      clipBehavior: Clip.none,
      // `loose` afrouxaria as constraints antes de chegarem no widget do
      // spec: `crossAxisAlignment: stretch` não esticaria no preview mas
      // esticaria no app do cliente.
      fit: StackFit.passthrough,
      children: [
        if (isDropTarget)
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: built,
          )
        else if (isSelected)
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: built,
          )
        else if (isHovered)
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: _hoverColor, width: 1.5),
            ),
            child: built,
          )
        else
          CustomPaint(
            foregroundPainter: DashedBorderPainter(color: mock.dropHint),
            child: built,
          ),
        if (isSelected || isHovered || isDropTarget)
          Positioned(
            top: -18,
            left: 0,
            child: NodeTag(label: label, isSelected: isSelected),
          ),
      ],
    );
  }
}
