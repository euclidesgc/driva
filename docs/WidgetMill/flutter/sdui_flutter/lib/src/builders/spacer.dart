import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../renderer.dart';

/// Spacer — spec §2.13.
Widget buildSpacer(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.props;
  return Spacer(flex: (p['flex'] as num?)?.toInt() ?? 1);
}
