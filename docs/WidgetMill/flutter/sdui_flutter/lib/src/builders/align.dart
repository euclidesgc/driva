import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Align — posiciona o filho dentro de si.
Widget buildAlign(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Align(
    alignment: alignmentFrom(p['alignment']) ?? Alignment.center,
    widthFactor: parseDouble(p['widthFactor']),
    heightFactor: parseDouble(p['heightFactor']),
    child: r.maybeRender(context, node.child),
  );
}
