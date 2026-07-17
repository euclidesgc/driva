import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildPadding(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Padding(
    padding: parseEdgeInsets(p['padding']) ?? EdgeInsets.zero,
    child: r.maybeRender(context, node.child),
  );
}
