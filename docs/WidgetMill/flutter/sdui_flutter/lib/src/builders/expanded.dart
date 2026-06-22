import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../renderer.dart';

/// Expanded — spec §2.12.
Widget buildExpanded(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Expanded(
    flex: (p['flex'] as num?)?.toInt() ?? 1,
    child: r.maybeRender(context, node.child) ?? const SizedBox.shrink(),
  );
}
