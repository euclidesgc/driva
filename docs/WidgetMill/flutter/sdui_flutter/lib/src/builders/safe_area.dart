import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../renderer.dart';

/// SafeArea — recua o filho dos intrusos do sistema (notch, status bar).
Widget buildSafeArea(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return SafeArea(
    top: p['top'] as bool? ?? true,
    bottom: p['bottom'] as bool? ?? true,
    left: p['left'] as bool? ?? true,
    right: p['right'] as bool? ?? true,
    child: r.maybeRender(context, node.child) ?? const SizedBox.shrink(),
  );
}
