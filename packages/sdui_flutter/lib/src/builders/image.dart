import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildImage(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  final src = (p['src'] ?? '').toString();
  final width = parseDouble(p['width']);
  final height = parseDouble(p['height']);

  if (src.isEmpty) {
    return SizedBox(
      width: width ?? 80,
      height: height ?? 80,
      child: const ColoredBox(color: Color(0x22000000)),
    );
  }
  return Image.network(
    src,
    width: width,
    height: height,
    fit: boxFitFrom(p['fit']),
    errorBuilder: (_, _, _) => SizedBox(
      width: width ?? 80,
      height: height ?? 80,
      child: const ColoredBox(color: Color(0x22000000)),
    ),
  );
}
