import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/palette_tile.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class PaletteItem extends StatelessWidget {
  const PaletteItem({
    required this.descriptor,
    this.isDraggable = true,
    super.key,
  });

  final WidgetDescriptor descriptor;

  /// Falso enquanto o rascunho está congelado pelo modo de comparação: o
  /// item continua visível — a paleta é parte da leitura da tela — mas sem
  /// o gesto e sem o cursor que o prometem.
  final bool isDraggable;

  @override
  Widget build(BuildContext context) {
    final tile = PaletteTile(descriptor: descriptor);
    if (!isDraggable) {
      return Opacity(
        opacity: 0.5,
        child: Tooltip(
          message: 'Feche a comparação para editar',
          child: tile,
        ),
      );
    }
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
