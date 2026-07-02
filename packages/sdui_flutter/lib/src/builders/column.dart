import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildColumn(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Column(
    mainAxisAlignment: mainAxisAlignmentFrom(p['mainAxisAlignment']),
    crossAxisAlignment: crossAxisAlignmentFrom(p['crossAxisAlignment']),
    mainAxisSize: mainAxisSizeFrom(p['mainAxisSize']),
    spacing: parseDouble(p['spacing']) ?? 0,
    children: r.renderAll(context, node.children),
  );
}
