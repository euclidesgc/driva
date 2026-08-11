import 'package:flutter/material.dart';

const Map<String, IconData> paletteIcons = {
  'container': Icons.crop_square,
  'column': Icons.view_agenda_outlined,
  'row': Icons.view_week_outlined,
  'stack': Icons.layers_outlined,
  'text': Icons.text_fields,
  'image': Icons.image_outlined,
  'icon': Icons.emoji_symbols,
  'button': Icons.smart_button,
  'textField': Icons.text_fields_outlined,
  'switch': Icons.toggle_on_outlined,
  'checkbox': Icons.check_box_outlined,
  'card': Icons.credit_card,
  'divider': Icons.horizontal_rule,
  'sizedBox': Icons.crop_free,
  'padding': Icons.padding_outlined,
  'center': Icons.filter_center_focus,
  'spacer': Icons.expand,
  'wrap': Icons.wrap_text,
  'expanded': Icons.open_in_full,
  'listView': Icons.list_alt_outlined,
  'gridView': Icons.grid_view_outlined,
  'radio': Icons.radio_button_checked,
  'dropdown': Icons.arrow_drop_down_circle_outlined,
  'slider': Icons.tune,
};

IconData paletteIconFor(String type) =>
    paletteIcons[type] ?? Icons.widgets_outlined;
