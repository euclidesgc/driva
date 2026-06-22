import 'package:flutter/material.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Card — superfície elevada do Material.
Widget buildCard(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  final br = parseBorderRadius(p['borderRadius']);
  return Card(
    color: parseColor(p['color']),
    elevation: parseDouble(p['elevation']),
    margin: parseEdgeInsets(p['margin']),
    shape: br != null ? RoundedRectangleBorder(borderRadius: br) : null,
    child: r.maybeRender(context, node.child),
  );
}
