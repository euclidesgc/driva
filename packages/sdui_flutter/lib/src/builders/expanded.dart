import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/flex_scope.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';
import 'package:sdui_flutter/src/renderer.dart';

/// Fora de um `Row`/`Column`, `Expanded` derrubaria a árvore por ParentData —
/// e no editor o usuário solta o widget onde quiser. Sem pai flexível, o nó
/// desenha só o filho.
Widget buildExpanded(BuildContext context, SduiNode node, SduiRenderer r) {
  final child = r.maybeRender(context, node.child) ?? const SizedBox.shrink();
  if (!SduiFlexScope.isInFlex(context)) return child;
  return Expanded(
    flex: parseInt(node.properties['flex']) ?? 1,
    child: child,
  );
}
