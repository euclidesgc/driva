import 'package:flutter/widgets.dart';
import 'actions/sdui_action.dart';
import 'model/sdui_node.dart';

/// Constrói um widget a partir de um nó. Recebe o renderer para descer na árvore.
typedef SduiBuilder = Widget Function(
  BuildContext context,
  SduiNode node,
  SduiRenderer renderer,
);

/// Mapa imutável `type → builder`. Adicionar um primitivo = uma entrada aqui.
class SduiRegistry {
  SduiRegistry(Map<String, SduiBuilder> builders)
      : _builders = Map.unmodifiable(builders);

  final Map<String, SduiBuilder> _builders;

  SduiBuilder? operator [](String type) => _builders[type];
  bool contains(String type) => _builders.containsKey(type);
  Iterable<String> get types => _builders.keys;
}

/// Percorre a árvore do spec produzindo widgets via [SduiRegistry].
class SduiRenderer {
  const SduiRenderer(this.registry, {this.onAction});

  final SduiRegistry registry;

  /// Handler de ações disparadas por eventos (tap, onPressed, ...).
  final SduiActionHandler? onAction;

  Widget render(BuildContext context, SduiNode node) {
    final builder = registry[node.type];
    if (builder == null) {
      return ErrorWidget('SDUI: tipo desconhecido "${node.type}"');
    }
    return builder(context, node, this);
  }

  /// Renderiza um filho opcional (`null` se ausente — para slots `child?`).
  Widget? maybeRender(BuildContext context, SduiNode? node) =>
      node == null ? null : render(context, node);

  /// Renderiza uma lista de filhos.
  List<Widget> renderAll(BuildContext context, List<SduiNode> nodes) =>
      [for (final n in nodes) render(context, n)];

  /// Executa, em ordem, a lista de ações de um evento. No-op sem handler.
  void dispatch(Object? actions) {
    final handler = onAction;
    if (handler == null || actions is! List) return;
    for (final a in actions) {
      if (a is Map) handler(SduiAction.fromJson(a.cast<String, dynamic>()));
    }
  }
}
