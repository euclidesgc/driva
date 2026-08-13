import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/layout/sdui_dimension_box.dart';
import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Flutter: `color` e `decoration` são mutuamente exclusivos — passar os dois
/// no mesmo Container lança em runtime.
///
/// A margem fica FORA do box de dimensão: no `Container` ela é aplicada por
/// último, depois das constraints, então `width: 100` + `margin: 8` ocupa 116.
/// Envolver tudo num `ConstrainedBox` mudaria isso para 100.
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

  return Padding(
    padding: parseEdgeInsets(p['margin']) ?? EdgeInsets.zero,
    child: SduiDimensionBox(
      width: p['width'],
      height: p['height'],
      minWidth: p['minWidth'],
      maxWidth: p['maxWidth'],
      minHeight: p['minHeight'],
      maxHeight: p['maxHeight'],
      child: Container(
        padding: parseEdgeInsets(p['padding']),
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
      ),
    ),
  );
}
