import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildDivider(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Divider(
    thickness: parseDouble(p['thickness']),
    indent: parseDouble(p['indent']),
    endIndent: parseDouble(p['endIndent']),
    color: parseColor(p['color']),
  );
}
