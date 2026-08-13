import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/widget_palette.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

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

  bool _matches(WidgetDescriptor descriptor) =>
      _query.isEmpty ||
      descriptor.label.toLowerCase().contains(_query) ||
      descriptor.type.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    // A ordem das categorias é do kernel, não da ordem de inserção do mapa:
    // é ela que faz a paleta abrir sempre igual, com ou sem filtro.
    final byCategory = <String, List<WidgetDescriptor>>{};
    for (final category in WidgetCategories.inPaletteOrder) {
      final matching = [
        for (final descriptor in widgetCatalog.values)
          if (descriptor.category == category && _matches(descriptor))
            descriptor,
      ];
      if (matching.isNotEmpty) byCategory[category] = matching;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: SearchField(
            hintText: 'Buscar widget…',
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
