import 'package:flutter/widgets.dart';
import 'actions/sdui_action.dart';
import 'binding/resolve_bindings.dart';
import 'builders/default_registry.dart';
import 'model/sdui_node.dart';
import 'renderer.dart';

/// Ponto de entrada público: renderiza um nó do spec como árvore de widgets.
class SduiView extends StatelessWidget {
  const SduiView({super.key, required this.node, this.registry, this.onAction});

  /// Constrói a partir do JSON cru do spec, resolvendo bindings/tokens se
  /// `data`/`tokens` forem fornecidos.
  factory SduiView.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    SduiRegistry? registry,
    SduiActionHandler? onAction,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> tokens = const {},
  }) {
    final resolved = (data.isEmpty && tokens.isEmpty)
        ? json
        : resolveBindings(json, data: data, tokens: tokens);
    return SduiView(
      key: key,
      node: SduiNode.fromJson(resolved),
      registry: registry,
      onAction: onAction,
    );
  }

  final SduiNode node;
  final SduiRegistry? registry;
  final SduiActionHandler? onAction;

  @override
  Widget build(BuildContext context) {
    final renderer = SduiRenderer(
      registry ?? defaultRegistry,
      onAction: onAction,
    );
    return renderer.render(context, node);
  }
}
