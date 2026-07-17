import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildDivider(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Divider(
    thickness: parseDouble(p['thickness']),
    indent: parseDouble(p['indent']),
    endIndent: parseDouble(p['endIndent']),
    color: parseColor(p['color']),
  );
}
