import 'package:flutter/material.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Divider — linha divisória horizontal.
Widget buildDivider(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Divider(
    height: parseDouble(p['height']),
    thickness: parseDouble(p['thickness']),
    indent: parseDouble(p['indent']),
    endIndent: parseDouble(p['endIndent']),
    color: parseColor(p['color']),
  );
}
