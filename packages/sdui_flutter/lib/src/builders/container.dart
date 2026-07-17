import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Flutter: `color` e `decoration` são mutuamente exclusivos — passar os dois
/// no mesmo Container lança em runtime.
Widget buildContainer(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final borderRadius = parseBorderRadius(p['borderRadius']);
  final borderColor = parseColor(p['borderColor']);
  final border = borderColor != null
      ? Border.all(
          color: borderColor,
          width: parseDouble(p['borderWidth']) ?? 1.0,
        )
      : null;
  final needsDecoration = borderRadius != null || border != null;

  return Container(
    width: parseDouble(p['width']),
    height: parseDouble(p['height']),
    padding: parseEdgeInsets(p['padding']),
    margin: parseEdgeInsets(p['margin']),
    alignment: alignmentFrom(p['alignment']),
    color: needsDecoration ? null : parseColor(p['color']),
    decoration: needsDecoration
        ? BoxDecoration(
            color: parseColor(p['color']),
            borderRadius: borderRadius,
            border: border,
          )
        : null,
    child: r.maybeRender(context, node.child),
  );
}
