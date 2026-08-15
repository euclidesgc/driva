import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/builders/default_registry.dart';
import 'package:sdui_flutter/src/layout/sdui_safe_area.dart';
import 'package:sdui_flutter/src/registry.dart';
import 'package:sdui_flutter/src/renderer.dart';

class SduiView extends StatelessWidget {
  const SduiView({
    required this.node,
    super.key,
    this.registry,
    this.onAction,
    this.nodeWrapper,
    this.safeArea,
    this.showDiagnostics = false,
  });

  SduiView.content(
    ContentSpec spec, {
    Key? key,
    SduiRegistry? registry,
    SduiActionHandler? onAction,
    SduiNodeWrapper? nodeWrapper,
    bool showDiagnostics = false,
  }) : this(
         key: key,
         node: spec.root,
         registry: registry,
         onAction: onAction,
         nodeWrapper: nodeWrapper,
         safeArea: spec.safeArea,
         showDiagnostics: showDiagnostics,
       );

  final SduiNode? node;
  final SduiRegistry? registry;
  final SduiActionHandler? onAction;
  final SduiNodeWrapper? nodeWrapper;

  /// Props da área segura da página. `null` = renderizar um nó solto, sem o
  /// chrome de página (o construtor `SduiView` cru).
  final Map<String, dynamic>? safeArea;

  /// Repassado ao [SduiRenderer] — só o editor liga.
  final bool showDiagnostics;

  @override
  Widget build(BuildContext context) {
    final root = node;
    if (root == null) return const SizedBox.shrink();
    final renderer = SduiRenderer(
      registry ?? defaultRegistry,
      onAction: onAction,
      nodeWrapper: nodeWrapper,
      showDiagnostics: showDiagnostics,
    );
    final rendered = renderer.render(context, root);
    final pageChrome = safeArea;
    if (pageChrome == null) return rendered;
    return SduiSafeArea(properties: pageChrome, child: rendered);
  }
}
