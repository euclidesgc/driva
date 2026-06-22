import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Row — spec §2.3.
Widget buildRow(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Row(
    mainAxisAlignment: mainAxisAlignmentFrom(p['mainAxisAlignment']),
    crossAxisAlignment: crossAxisAlignmentFrom(p['crossAxisAlignment']),
    mainAxisSize: mainAxisSizeFrom(p['mainAxisSize']),
    spacing: parseDouble(p['spacing']) ?? 0,
    children: r.renderAll(context, node.children),
  );
}
