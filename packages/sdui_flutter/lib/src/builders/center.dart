import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildCenter(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Center(
    widthFactor: parseDouble(p['widthFactor']),
    heightFactor: parseDouble(p['heightFactor']),
    child: r.maybeRender(context, node.child),
  );
}
