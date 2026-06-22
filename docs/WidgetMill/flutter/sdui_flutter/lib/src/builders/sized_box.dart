import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// SizedBox — spec §2.9.
Widget buildSizedBox(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return SizedBox(
    width: resolveDimension(context, p['width']),
    height: resolveDimension(context, p['height']),
    child: r.maybeRender(context, node.child),
  );
}
