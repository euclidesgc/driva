import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/parsers.dart';
import '../renderer.dart';

/// Opacity — aplica opacidade (0..1) ao filho.
Widget buildOpacity(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Opacity(
    opacity: (parseDouble(p['opacity']) ?? 1.0).clamp(0.0, 1.0),
    child: r.maybeRender(context, node.child),
  );
}
