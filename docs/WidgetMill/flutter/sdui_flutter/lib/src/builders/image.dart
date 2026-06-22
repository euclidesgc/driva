import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Image — spec §2.6.
Widget buildImage(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  final src = (p['src'] ?? '').toString();
  final width = resolveDimension(context, p['width']);
  final height = resolveDimension(context, p['height']);
  final fit = boxFitFrom(p['fit']);

  if (p['source'] == 'asset') {
    return Image.asset(src, width: width, height: height, fit: fit);
  }
  return Image.network(src, width: width, height: height, fit: fit);
}
