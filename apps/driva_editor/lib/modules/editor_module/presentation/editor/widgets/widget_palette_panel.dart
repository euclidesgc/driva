import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/editor_colors.dart';
import 'drag_payload.dart';
import 'palette_icons.dart';

/// Paleta de widgets: itens **arrastáveis** para a árvore/canvas, agrupados
/// por categoria, com busca. Adicionar é só por drag-and-drop (o clique não
/// adiciona — o usuário controla onde solta).
class WidgetPalettePanel extends StatefulWidget {
  const WidgetPalettePanel({super.key});

  @override
  State<WidgetPalettePanel> createState() => _WidgetPalettePanelState();
}

class _WidgetPalettePanelState extends State<WidgetPalettePanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<WidgetDescriptor>>{};
    for (final descriptor in widgetCatalog.values) {
      final matches =
          _query.isEmpty ||
          descriptor.label.toLowerCase().contains(_query) ||
          descriptor.type.toLowerCase().contains(_query);
      if (matches) {
        byCategory.putIfAbsent(descriptor.category, () => []).add(descriptor);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar widget…',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: byCategory.isEmpty
              ? const Center(child: Text('Nenhum widget encontrado.'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final entry in byCategory.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).extension<EditorColors>()!.inkMuted,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final descriptor in entry.value)
                              _PaletteItem(descriptor: descriptor),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({required this.descriptor});

  final WidgetDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final tile = _PaletteTile(descriptor: descriptor);
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

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.descriptor});

  final WidgetDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paletteIconFor(descriptor.type),
            size: 22,
            color: colors.inkPrimary,
          ),
          const SizedBox(height: 6),
          Text(
            descriptor.label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
