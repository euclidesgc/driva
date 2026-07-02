import 'package:flutter/material.dart';

/// Ícones da paleta/árvore por primitivo (visual do editor, não do spec —
/// os ícones do spec vivem no catálogo curado do renderer).
const Map<String, IconData> paletteIcons = {
  'container': Icons.crop_square,
  'column': Icons.view_agenda_outlined,
  'row': Icons.view_week_outlined,
  'stack': Icons.layers_outlined,
  'text': Icons.text_fields,
  'image': Icons.image_outlined,
  'icon': Icons.emoji_symbols,
  'button': Icons.smart_button,
  'card': Icons.credit_card,
  'divider': Icons.horizontal_rule,
  'sizedBox': Icons.crop_free,
  'padding': Icons.padding_outlined,
  'center': Icons.filter_center_focus,
  'spacer': Icons.expand,
};

IconData paletteIconFor(String type) =>
    paletteIcons[type] ?? Icons.widgets_outlined;
