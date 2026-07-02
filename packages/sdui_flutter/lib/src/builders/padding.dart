import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildPadding(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Padding(
    padding: parseEdgeInsets(p['padding']) ?? EdgeInsets.zero,
    child: r.maybeRender(context, node.child),
  );
}
