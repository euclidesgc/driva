import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// AspectRatio — força uma razão largura/altura no filho.
Widget buildAspectRatio(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return AspectRatio(
    aspectRatio: parseDouble(p['aspectRatio']) ?? 1.0,
    child: r.maybeRender(context, node.child),
  );
}
