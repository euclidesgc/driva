import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildSizedBox(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return SizedBox(
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    child: r.maybeRender(context, node.child),
  );
}
