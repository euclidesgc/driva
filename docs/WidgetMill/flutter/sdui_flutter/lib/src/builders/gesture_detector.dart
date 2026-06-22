import 'package:flutter/widgets.dart';
import '../model/sdui_node.dart';
import '../renderer.dart';

/// GestureDetector — spec §2.14. Liga onTap/onLongPress/onDoubleTap ao dispatcher.
Widget buildGestureDetector(BuildContext context, SduiNode node, SduiRenderer r) {
  final e = node.events;
  VoidCallback? wire(String event) =>
      e[event] == null ? null : () => r.dispatch(e[event]);

  return GestureDetector(
    onTap: wire('onTap'),
    onLongPress: wire('onLongPress'),
    onDoubleTap: wire('onDoubleTap'),
    child: r.maybeRender(context, node.child),
  );
}
