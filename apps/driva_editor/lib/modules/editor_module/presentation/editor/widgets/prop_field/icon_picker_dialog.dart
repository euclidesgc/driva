import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart'
    show iconFallback, iconLibraries, parseIconRef;

/// Resultado do modal: `value` nulo significa "None" (limpar o ícone).
typedef IconPickerResult = ({String? value});

/// Modal "Choose Icon": busca, abas por biblioteca (com contagem) e grade
/// virtualizada de prévias. Devolve `"biblioteca:nome"` ao tocar numa célula.
class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({
    required this.selected,
    required this.allowNone,
    this.libraries = iconLibraries,
    super.key,
  });

  final String? selected;
  final bool allowNone;
  final Map<String, Map<String, IconData>> libraries;

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final libs = widget.libraries.keys.toList(growable: false);
    final selected = widget.selected == null
        ? null
        : parseIconRef(widget.selected!);
    return DefaultTabController(
      length: libs.length,
      child: Dialog(
        child: SizedBox(
          width: 480,
          height: 440,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose Icon',
                        style: TextStyle(
                          fontSize: AppTypography.base,
                          fontWeight: FontWeight.w600,
                          color: colors.inkPrimary,
                        ),
                      ),
                    ),
                    if (widget.allowNone)
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop<IconPickerResult>((value: null)),
                        child: const Text('None'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search icons…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 8),
                TabBar(
                  tabs: [
                    for (final l in libs)
                      Tab(
                        text: '${_label(l)} (${widget.libraries[l]!.length})',
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final l in libs)
                        _IconGrid(
                          library: l,
                          icons: _filter(widget.libraries[l]!),
                          selected: selected != null && selected.library == l
                              ? selected.name
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, IconData> _filter(Map<String, IconData> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return {
      for (final e in all.entries)
        if (e.key.toLowerCase().contains(q)) e.key: e.value,
    };
  }

  static String _label(String lib) => switch (lib) {
    'material' => 'Material',
    _ => lib,
  };
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.library,
    required this.icons,
    required this.selected,
  });

  final String library;
  final Map<String, IconData> icons;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) {
      return const Center(child: Text('Nenhum ícone'));
    }
    final names = icons.keys.toList(growable: false);
    return GridView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 72,
      ),
      itemCount: names.length,
      itemBuilder: (context, i) {
        final name = names[i];
        return IconPickerCell(
          name: name,
          icon: icons[name]!,
          selected: name == selected,
          onTap: () => Navigator.of(
            context,
          ).pop<IconPickerResult>((value: '$library:$name')),
        );
      },
    );
  }
}

/// Célula da grade: prévia do ícone com o nome em tooltip.
class IconPickerCell extends StatelessWidget {
  const IconPickerCell({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(AppRadii.r6),
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

/// Ícone mostrado no botão do campo para o valor atual.
IconData previewIconFor(
  String? value,
  Map<String, Map<String, IconData>> libraries,
) {
  if (value == null) return iconFallback;
  final ref = parseIconRef(value);
  return libraries[ref.library]?[ref.name] ?? iconFallback;
}
