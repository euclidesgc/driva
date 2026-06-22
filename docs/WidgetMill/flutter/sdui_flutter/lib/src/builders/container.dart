import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Container — spec §2.1.
Widget buildContainer(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  final decoration = parseBoxDecoration(p['decoration']);
  return Container(
    width: resolveDimension(context, p['width']),
    height: resolveDimension(context, p['height']),
    padding: parseEdgeInsets(p['padding']),
    margin: parseEdgeInsets(p['margin']),
    alignment: alignmentFrom(p['alignment']),
    // color e decoration são mutuamente exclusivos (Flutter); o kernel já garante
    // que não venham juntos, mas mantemos a defesa aqui.
    color: decoration == null ? parseColor(p['color']) : null,
    decoration: decoration,
    constraints: parseBoxConstraints(p['constraints']),
    child: r.maybeRender(context, node.child),
  );
}
