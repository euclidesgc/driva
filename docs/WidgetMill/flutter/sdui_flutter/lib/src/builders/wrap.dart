import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Wrap — flui os filhos em múltiplas linhas/colunas.
Widget buildWrap(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Wrap(
    direction: axisFrom(p['direction']),
    alignment: wrapAlignmentFrom(p['alignment']),
    runAlignment: wrapAlignmentFrom(p['runAlignment']),
    crossAxisAlignment: wrapCrossFrom(p['crossAxisAlignment']),
    spacing: parseDouble(p['spacing']) ?? 0,
    runSpacing: parseDouble(p['runSpacing']) ?? 0,
    children: r.renderAll(context, node.children),
  );
}
