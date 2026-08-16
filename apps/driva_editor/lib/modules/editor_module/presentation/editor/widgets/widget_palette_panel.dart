import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/widget_palette.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Paleta de widgets: itens **arrastáveis** para a árvore/canvas, agrupados
/// por categoria colapsável, com busca. Adicionar é só por drag-and-drop (o
/// clique não adiciona — o usuário controla onde solta).
class WidgetPalettePanel extends StatefulWidget {
  const WidgetPalettePanel({required this.collapsedCategories, super.key});

  final ValueNotifier<Set<String>> collapsedCategories;

  @override
  State<WidgetPalettePanel> createState() => _WidgetPalettePanelState();
}

class _WidgetPalettePanelState extends State<WidgetPalettePanel> {
  String _query = '';

  bool _matches(WidgetDescriptor descriptor) =>
      _query.isEmpty ||
      descriptor.label.toLowerCase().contains(_query) ||
      descriptor.type.toLowerCase().contains(_query);

  void _toggleCategory(String category) {
    final collapsed = {...widget.collapsedCategories.value};
    if (!collapsed.remove(category)) {
      collapsed.add(category);
    }
    widget.collapsedCategories.value = collapsed;
  }

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

    final hasQuery = _query.isNotEmpty;

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
              : ValueListenableBuilder<Set<String>>(
                  valueListenable: widget.collapsedCategories,
                  builder: (context, collapsedCategories, _) => ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                    children: [
                      for (final entry in byCategory.entries)
                        PaletteCategorySection(
                          category: entry.key,
                          descriptors: entry.value,
                          isExpanded:
                              hasQuery ||
                              !collapsedCategories.contains(entry.key),
                          onToggle: hasQuery
                              ? null
                              : () => _toggleCategory(entry.key),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
