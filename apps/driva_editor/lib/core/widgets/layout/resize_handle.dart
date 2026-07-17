import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class ResizeHandle extends StatelessWidget {
  const ResizeHandle({required this.onDrag, super.key});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: SizedBox(
          width: 6,
          child: Center(
            child: SizedBox(width: 1, child: ColoredBox(color: colors.border)),
          ),
        ),
      ),
    );
  }
}
