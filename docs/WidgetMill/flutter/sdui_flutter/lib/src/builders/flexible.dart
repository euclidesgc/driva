import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../parsing/enums.dart';
import '../renderer.dart';

/// Flexible — spec §2.12.
Widget buildFlexible(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Flexible(
    flex: (p['flex'] as num?)?.toInt() ?? 1,
    fit: flexFitFrom(p['fit']),
    child: r.maybeRender(context, node.child) ?? const SizedBox.shrink(),
  );
}
