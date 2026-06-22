import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../renderer.dart';

/// Stack — spec §2.4.
Widget buildStack(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Stack(
    alignment: alignmentDirectionalFrom(p['alignment']),
    fit: stackFitFrom(p['fit']),
    clipBehavior: clipFrom(p['clipBehavior']),
    children: r.renderAll(context, node.children),
  );
}
