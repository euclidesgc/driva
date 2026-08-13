import 'package:flutter/material.dart';

/// Resolve o `iconName` simbólico que o catálogo declara em cada `PropOption`.
/// `IconData` const não sobrevive a lookup por string em runtime
/// (tree-shaking), então o mapa é explícito — mesmo contrato do
/// `material_icons.dart` do renderer, mas este vocabulário é do chrome do
/// editor, não do spec.
abstract final class PropIcons {
  static const _icons = <String, IconData>{
    'flexStart': Icons.align_vertical_top,
    'flexCenter': Icons.align_vertical_center,
    'flexEnd': Icons.align_vertical_bottom,
    'flexSpaceBetween': Icons.vertical_distribute,
    'flexSpaceAround': Icons.space_bar,
    'flexSpaceEvenly': Icons.density_medium,
    'crossStart': Icons.align_horizontal_left,
    'crossCenter': Icons.align_horizontal_center,
    'crossEnd': Icons.align_horizontal_right,
    'crossStretch': Icons.height,
    'sizeMax': Icons.unfold_more,
    'sizeMin': Icons.unfold_less,
    'textAlignStart': Icons.format_align_left,
    'textAlignCenter': Icons.format_align_center,
    'textAlignEnd': Icons.format_align_right,
    'textAlignJustify': Icons.format_align_justify,
    'textAlignLeft': Icons.west,
    'textAlignRight': Icons.east,
    'borderOutline': Icons.check_box_outline_blank,
    'borderUnderline': Icons.format_underlined,
    'borderFilled': Icons.format_color_fill,
    'axisHorizontal': Icons.swap_horiz,
    'axisVertical': Icons.swap_vert,
    'edgeUniform': Icons.crop_square,
    'edgeIndividual': Icons.border_outer,
    'resetToDefault': Icons.settings_backup_restore,
  };

  static IconData? resolve(String? name) => name == null ? null : _icons[name];

  static bool has(String? name) => resolve(name) != null;
}
