import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildCenter(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Center(
    widthFactor: parseDouble(p['widthFactor']),
    heightFactor: parseDouble(p['heightFactor']),
    child: r.maybeRender(context, node.child),
  );
}
