import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Positioned — spec §2.4 (filho de Stack).
Widget buildPositioned(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Positioned(
    left: parseDouble(p['left']),
    top: parseDouble(p['top']),
    right: parseDouble(p['right']),
    bottom: parseDouble(p['bottom']),
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    child: r.maybeRender(context, node.child) ?? const SizedBox.shrink(),
  );
}
