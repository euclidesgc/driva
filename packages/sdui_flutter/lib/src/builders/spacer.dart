import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/flex_scope.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// `Spacer` é `Expanded` por dentro: fora de um `Row`/`Column` ele derruba a
/// árvore por ParentData. No editor o usuário move o nó para onde quiser, então
/// sem pai flexível o nó simplesmente não ocupa espaço.
Widget buildSpacer(BuildContext context, SduiNode node, SduiRenderer r) {
  if (!SduiFlexScope.isInFlex(context)) return const SizedBox.shrink();
  return Spacer(flex: parseInt(node.properties['flex']) ?? 1);
}
