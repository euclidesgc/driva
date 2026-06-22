import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Column — spec §2.2.
Widget buildColumn(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Column(
    mainAxisAlignment: mainAxisAlignmentFrom(p['mainAxisAlignment']),
    crossAxisAlignment: crossAxisAlignmentFrom(p['crossAxisAlignment']),
    mainAxisSize: mainAxisSizeFrom(p['mainAxisSize']),
    spacing: parseDouble(p['spacing']) ?? 0,
    children: r.renderAll(context, node.children),
  );
}
