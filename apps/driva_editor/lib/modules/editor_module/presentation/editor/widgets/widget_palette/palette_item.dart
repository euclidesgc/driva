import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../drag_payload.dart';
import 'palette_tile.dart';

class PaletteItem extends StatelessWidget {
  const PaletteItem({super.key, required this.descriptor});

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
