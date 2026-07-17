import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/material_icons.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildIcon(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Icon(
    iconDataFrom(p['icon']),
    size: parseDouble(p['size']) ?? 24,
    color: parseColor(p['color']),
  );
}
