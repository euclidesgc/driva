import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Text. Props planas (`fontSize`, `fontWeight`, `color`) — o estilo é
/// montado aqui, não num objeto `style` aninhado (decisão do catálogo I1).
Widget buildText(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Text(
    (p['data'] ?? '').toString(),
    style: TextStyle(
      fontSize: parseDouble(p['fontSize']),
      fontWeight: parseFontWeight(p['fontWeight']),
      color: parseColor(p['color']),
    ),
    textAlign: textAlignFrom(p['textAlign']),
    maxLines: parseInt(p['maxLines']),
    overflow: textOverflowFrom(p['overflow']),
  );
}
