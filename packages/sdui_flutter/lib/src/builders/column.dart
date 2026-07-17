import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

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
