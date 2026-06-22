import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/material_icons.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Icon — spec §2.7 (catálogo curado de Material Icons).
Widget buildIcon(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Icon(
    iconDataFrom(p['icon']),
    size: parseDouble(p['size']) ?? 24,
    color: parseColor(p['color']),
  );
}
