import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'builders/default_registry.dart';
import 'registry.dart';
import 'renderer.dart';

class SduiView extends StatelessWidget {
  const SduiView({
    super.key,
    required this.node,
    this.registry,
    this.onAction,
    this.nodeWrapper,
  });

  SduiView.content(
    ContentSpec spec, {
    Key? key,
    SduiRegistry? registry,
    SduiActionHandler? onAction,
    SduiNodeWrapper? nodeWrapper,
  }) : this(
         key: key,
         node: spec.root,
         registry: registry,
         onAction: onAction,
         nodeWrapper: nodeWrapper,
       );

  final SduiNode? node;
  final SduiRegistry? registry;
  final SduiActionHandler? onAction;
  final SduiNodeWrapper? nodeWrapper;

  @override
  Widget build(BuildContext context) {
    final root = node;
    if (root == null) return const SizedBox.shrink();
    final renderer = SduiRenderer(
      registry ?? defaultRegistry,
      onAction: onAction,
      nodeWrapper: nodeWrapper,
    );
    return renderer.render(context, root);
  }
}
