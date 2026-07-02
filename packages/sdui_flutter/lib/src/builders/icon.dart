import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/material_icons.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildIcon(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Icon(
    iconDataFrom(p['icon']),
    size: parseDouble(p['size']) ?? 24,
    color: parseColor(p['color']),
  );
}
