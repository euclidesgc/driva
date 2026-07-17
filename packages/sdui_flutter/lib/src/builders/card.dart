import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildCard(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final borderRadius = parseBorderRadius(p['borderRadius']);
  return Card(
    color: parseColor(p['color']),
    elevation: parseDouble(p['elevation']),
    margin: parseEdgeInsets(p['margin']),
    shape: borderRadius != null
        ? RoundedRectangleBorder(borderRadius: borderRadius)
        : null,
    child: r.maybeRender(context, node.child),
  );
}
