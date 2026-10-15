import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

class SduiGestureTriggers extends StatelessWidget {
  const SduiGestureTriggers({
    required this.triggers,
    required this.onTrigger,
    required this.child,
    super.key,
  });

  final Set<EventTrigger> triggers;
  final ValueChanged<EventTrigger> onTrigger;
  final Widget child;

  VoidCallback? _callbackFor(EventTrigger trigger) =>
      triggers.contains(trigger) ? () => onTrigger(trigger) : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _callbackFor(EventTrigger.onTap),
      onDoubleTap: _callbackFor(EventTrigger.onDoubleTap),
      onLongPress: _callbackFor(EventTrigger.onLongPress),
      child: child,
    );
  }
}
