import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/layout/sdui_dimension_box.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildSizedBox(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return SduiDimensionBox(
    width: p['width'],
    height: p['height'],
    child: r.maybeRender(context, node.child) ?? const SizedBox.shrink(),
  );
}
