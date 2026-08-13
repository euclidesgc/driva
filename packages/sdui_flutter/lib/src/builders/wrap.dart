import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildWrap(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Wrap(
    direction: axisFrom(p['direction']),
    alignment: wrapAlignmentFrom(p['alignment']),
    spacing: parseDouble(p['spacing']) ?? 0,
    runSpacing: parseDouble(p['runSpacing']) ?? 0,
    children: r.renderAll(context, node.children),
  );
}
