import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildSizedBox(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return SizedBox(
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    child: r.maybeRender(context, node.child),
  );
}
