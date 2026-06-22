import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Center — spec §2.11.
Widget buildCenter(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Center(
    widthFactor: parseDouble(p['widthFactor']),
    heightFactor: parseDouble(p['heightFactor']),
    child: r.maybeRender(context, node.child),
  );
}
