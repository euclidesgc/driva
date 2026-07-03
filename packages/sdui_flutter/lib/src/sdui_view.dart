import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'builders/default_registry.dart';
import 'registry.dart';
import 'renderer.dart';

/// Ponto de entrada público: renderiza um nó do spec como árvore de widgets.
///
/// No editor, o preview é `SduiView.content(spec, nodeWrapper: ...)` — a mesma
/// árvore Dart em memória, sem iframe; cada emit do cubit re-renderiza.
class SduiView extends StatelessWidget {
  const SduiView({
    super.key,
    required this.node,
    this.registry,
    this.onAction,
    this.nodeWrapper,
  });

  /// Renderiza um conteúdo inteiro (a partir do `root`).
  ///
  /// Recebe um [ContentSpec] já resolvido — não busca por slug nem faz rede.
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

  final SduiNode node;
  final SduiRegistry? registry;
  final SduiActionHandler? onAction;
  final SduiNodeWrapper? nodeWrapper;

  @override
  Widget build(BuildContext context) {
    final renderer = SduiRenderer(
      registry ?? defaultRegistry,
      onAction: onAction,
      nodeWrapper: nodeWrapper,
    );
    return renderer.render(context, node);
  }
}
