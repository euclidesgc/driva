import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

Widget buildSpacer(BuildContext context, SduiNode node, SduiRenderer r) {
  return Spacer(flex: parseInt(node.properties['flex']) ?? 1);
}
