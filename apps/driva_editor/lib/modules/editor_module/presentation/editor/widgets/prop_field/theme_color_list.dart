import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Papéis cujo nome contém [query], sem distinguir maiúsculas.
List<ThemeColorRole> filterThemeRoles(String query) {
  final needle = query.trim().toLowerCase();
  return [
    for (final role in ThemeColorRole.values)
      if (role.name.toLowerCase().contains(needle)) role,
  ];
}

/// `#RRGGBB` ou `#AARRGGBB` do tema para `Color`.
Color? parseThemeHex(String? hex) {
  if (hex == null || !hex.startsWith('#')) return null;
  var digits = hex.substring(1);
  if (digits.length == 6) digits = 'FF$digits';
  final value = int.tryParse(digits, radix: 16);
  return value == null ? null : Color(value);
}

class ThemeColorList extends StatefulWidget {
  const ThemeColorList({
    required this.onSelected,
    this.theme = kDefaultProjectTheme,
    this.selected,
    super.key,
  });

  final ProjectTheme theme;
  final String? selected;
  final ValueChanged<ThemeColorRole> onSelected;

  @override
  State<ThemeColorList> createState() => _ThemeColorListState();
}

class _ThemeColorListState extends State<ThemeColorList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final roles = filterThemeRoles(_query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          style: const TextStyle(fontSize: AppTypography.base),
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Buscar cores do tema',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
        const SizedBox(height: AppSpacing.s8),
        Expanded(
          child: ListView(
            children: [
              for (final role in roles)
                ListTile(
                  key: ValueKey('theme-color-${role.name}'),
                  dense: true,
                  selected: widget.selected == role.name,
                  leading: Container(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    decoration: BoxDecoration(
                      color: parseThemeHex(widget.theme.colors[role]),
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(AppRadii.r4),
                    ),
                  ),
                  title: Text(role.name),
                  subtitle: Text(widget.theme.colors[role] ?? ''),
                  onTap: () => widget.onSelected(role),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
