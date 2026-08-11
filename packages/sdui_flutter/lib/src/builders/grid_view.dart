import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildGridView(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return GridView.count(
    crossAxisCount: parseInt(p['crossAxisCount']) ?? 2,
    mainAxisSpacing: parseDouble(p['mainAxisSpacing']) ?? 0,
    crossAxisSpacing: parseDouble(p['crossAxisSpacing']) ?? 0,
    childAspectRatio: parseDouble(p['childAspectRatio']) ?? 1,
    padding: parseEdgeInsets(p['padding']),
    shrinkWrap: p['shrinkWrap'] as bool? ?? true,
    children: r.renderAll(context, node.children),
  );
}
