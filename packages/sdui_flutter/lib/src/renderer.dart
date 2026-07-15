import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'registry.dart';

/// Envolve o widget construído de cada nó. É o gancho que o editor usa para
/// contorno de seleção e hit-test por id, sem poluir os builders.
typedef SduiNodeWrapper = Widget Function(SduiNode node, Widget built);

/// Handler das ações disparadas por eventos do spec (`onPressed`, ...).
typedef SduiActionHandler = void Function(SduiAction action);

/// Percorre a árvore do spec produzindo widgets via [SduiRegistry].
class SduiRenderer {
  const SduiRenderer(this.registry, {this.onAction, this.nodeWrapper});

  final SduiRegistry registry;
  final SduiActionHandler? onAction;
  final SduiNodeWrapper? nodeWrapper;

  Widget render(BuildContext context, SduiNode node) =>
      _SduiNodeView(key: ValueKey(node.id), renderer: this, node: node);

  /// Renderiza um filho opcional (`null` se ausente — para slots `child`).
  Widget? maybeRender(BuildContext context, SduiNode? node) =>
      node == null ? null : render(context, node);

  /// Renderiza uma lista de filhos.
  List<Widget> renderAll(BuildContext context, List<SduiNode> nodes) => [
    for (final n in nodes) render(context, n),
  ];

  /// Executa, em ordem, a lista de ações de um evento. No-op sem handler.
  void dispatch(Object? actions) {
    final handler = onAction;
    if (handler == null || actions is! List) return;
    for (final a in actions) {
      if (a is Map) {
        handler(SduiAction.fromJson(a.cast<String, dynamic>()));
      }
    }
  }
}

/// Cada nó do spec vira um [StatelessWidget] próprio, chaveado pelo `id`.
///
/// Isola o rebuild no ponto certo: uma mudança num nó reconstrói só o seu
/// subtree — não o preview inteiro —, e a `ValueKey(id)` preserva a identidade
/// de elemento/estado quando um nó se move na árvore. É transparente ao render
/// tree (não introduz `RenderObject`), então o pixel e o parent-data (ex.:
/// `Expanded` dentro de um `Row`/`Column`) continuam idênticos.
class _SduiNodeView extends StatelessWidget {
  const _SduiNodeView({super.key, required this.renderer, required this.node});

  final SduiRenderer renderer;
  final SduiNode node;

  @override
  Widget build(BuildContext context) {
    final builder = renderer.registry[node.type];
    final built = builder == null
        ? _UnknownTypeBox(type: node.type)
        : builder(context, node, renderer);
    final wrapper = renderer.nodeWrapper;
    return wrapper == null ? built : wrapper(node, built);
  }
}

/// Fallback amigável para tipo fora do registry: no editor é melhor mostrar
/// o problema no lugar do bloco do que derrubar o preview inteiro.
class _UnknownTypeBox extends StatelessWidget {
  const _UnknownTypeBox({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCC3333)),
      ),
      child: Text(
        'Tipo desconhecido: "$type"',
        style: const TextStyle(color: Color(0xFFCC3333), fontSize: 12),
      ),
    );
  }
}
