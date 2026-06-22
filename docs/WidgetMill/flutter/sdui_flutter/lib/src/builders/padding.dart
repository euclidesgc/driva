import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Padding — spec §2.10.
Widget buildPadding(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Padding(
    padding: parseEdgeInsets(p['padding']) ?? EdgeInsets.zero,
    child: r.maybeRender(context, node.child),
  );
}
