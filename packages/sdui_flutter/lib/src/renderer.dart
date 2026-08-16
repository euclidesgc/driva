import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/flex_scope.dart';
import 'package:sdui_flutter/src/registry.dart';
import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

typedef SduiNodeWrapper = Widget Function(SduiNode node, Widget built);

typedef SduiActionHandler = void Function(SduiAction action);

/// Reescreve a URL de uma imagem antes do builder buscá-la. `null` = usa a
/// URL do spec como está — é o default, e é o que vale para o app cliente.
/// Só o editor liga um resolver (mesma fronteira de `showDiagnostics`): o
/// caminho é chrome de autoria, não contrato do renderer.
typedef SduiImageUrlResolver = String Function(String src);

class SduiRenderer {
  const SduiRenderer(
    this.registry, {
    this.onAction,
    this.nodeWrapper,
    this.showDiagnostics = false,
    this.imageUrlResolver,
  });

  final SduiRegistry registry;
  final SduiActionHandler? onAction;
  final SduiNodeWrapper? nodeWrapper;

  /// `true` só no editor. Builders podem usá-lo para decidir se expõem
  /// detalhe interno (URL, mensagem crua de exceção) — o mesmo renderer
  /// desenha o app publicado, onde esse detalhe não pode vazar ao usuário
  /// final (ex.: URL assinada com token na query).
  final bool showDiagnostics;

  final SduiImageUrlResolver? imageUrlResolver;

  Widget render(BuildContext context, SduiNode node) =>
      _SduiNodeView(key: ValueKey(node.id), renderer: this, node: node);

  Widget? maybeRender(BuildContext context, SduiNode? node) => node == null
      ? null
      : SduiFlexScope(isFlexParent: false, child: render(context, node));

  List<Widget> renderAll(BuildContext context, List<SduiNode> nodes) => [
    for (final n in nodes)
      SduiFlexScope(isFlexParent: false, child: render(context, n)),
  ];

  /// Filhos de `Row`/`Column`: só aqui `Expanded` é legal.
  List<Widget> renderFlexChildren(
    BuildContext context,
    List<SduiNode> nodes,
  ) => [
    for (final n in nodes)
      SduiFlexScope(isFlexParent: true, child: render(context, n)),
  ];

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

class _SduiNodeView extends StatelessWidget {
  const _SduiNodeView({required this.renderer, required this.node, super.key});

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

class _UnknownTypeBox extends StatelessWidget {
  const _UnknownTypeBox({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SduiChromeTokens.unknownTypePadding,
      decoration: BoxDecoration(
        border: Border.all(color: SduiChromeTokens.unknownTypeAccent),
      ),
      child: Text(
        'Tipo desconhecido: "$type"',
        style: const TextStyle(
          color: SduiChromeTokens.unknownTypeAccent,
          fontSize: SduiChromeTokens.unknownTypeFontSize,
        ),
      ),
    );
  }
}
