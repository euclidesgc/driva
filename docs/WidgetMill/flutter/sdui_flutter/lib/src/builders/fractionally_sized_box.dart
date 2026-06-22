import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// FractionallySizedBox — dimensiona o filho como fração do espaço do pai.
Widget buildFractionallySizedBox(
    BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return FractionallySizedBox(
    widthFactor: parseDouble(p['widthFactor']),
    heightFactor: parseDouble(p['heightFactor']),
    alignment: alignmentFrom(p['alignment']) ?? Alignment.center,
    child: r.maybeRender(context, node.child),
  );
}
