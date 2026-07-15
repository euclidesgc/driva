import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/editor_colors.dart';
import 'widget_palette/widget_palette.dart';

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
          padding: const EdgeInsets.all(AppSpacing.s12),
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  children: [
                    for (final entry in byCategory.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s12,
                          AppSpacing.s8,
                          AppSpacing.s12,
                          AppSpacing.s4,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            for (final descriptor in entry.value)
                              PaletteItem(descriptor: descriptor),
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
