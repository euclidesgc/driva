import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/palette_tile.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class PaletteItem extends StatelessWidget {
  const PaletteItem({required this.descriptor, super.key});

  final WidgetDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final tile = PaletteTile(descriptor: descriptor);
    return Draggable<DragPayload>(
      data: PaletteDragPayload(descriptor.type),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.85, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(message: 'Arraste para o conteúdo', child: tile),
      ),
    );
  }
}
