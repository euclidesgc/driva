import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import '../parsing/parsers.dart';
import '../renderer.dart';

Widget buildSpacer(BuildContext context, SduiNode node, SduiRenderer r) {
  return Spacer(flex: parseInt(node.properties['flex']) ?? 1);
}
