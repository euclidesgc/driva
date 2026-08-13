import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildListView(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return ListView(
    scrollDirection: axisFrom(p['scrollDirection']),
    padding: parseEdgeInsets(p['padding']),
    shrinkWrap: p['shrinkWrap'] as bool? ?? true,
    children: r.renderAll(context, node.children),
  );
}
