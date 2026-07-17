import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/enums.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildStack(BuildContext context, SduiNode node, SduiRenderer r) {
  final p = node.properties;
  return Stack(
    alignment: alignmentFrom(p['alignment']) ?? AlignmentDirectional.topStart,
    fit: stackFitFrom(p['fit']),
    children: r.renderAll(context, node.children),
  );
}
