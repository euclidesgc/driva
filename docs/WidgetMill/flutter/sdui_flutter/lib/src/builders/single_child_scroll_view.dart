import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// SingleChildScrollView — torna o filho rolável num eixo.
Widget buildSingleChildScrollView(
    BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return SingleChildScrollView(
    // Default do Flutter é vertical (≠ Wrap.direction, que é horizontal).
    scrollDirection: axisFrom(p['scrollDirection'] ?? 'vertical'),
    reverse: p['reverse'] as bool? ?? false,
    padding: parseEdgeInsets(p['padding']),
    child: r.maybeRender(context, node.child),
  );
}
