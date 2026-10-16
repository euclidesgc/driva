import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/flex_scope.dart';
import 'package:sdui_flutter/src/registry.dart';
import 'package:sdui_flutter/src/sdui_gesture_triggers.dart';
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
    this.boundValueDisplay = BoundValueDisplay.fallback,
    this.theme = kDefaultProjectTheme,
    this.componentLookup,
    this.authoringMode = false,
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

  /// Como um `$bind` aparece quando não há dado em tempo de execução: o
  /// app cliente usa `fallback`; o editor liga `preview`.
  final BoundValueDisplay boundValueDisplay;

  final ProjectTheme theme;

  /// Busca de componentes (`id → ContentSpec`) para desenhar nós `component`.
  /// `null` no app cliente, que recebe a árvore já expandida: ali a instância
  /// cai na caixa de erro.
  final ComponentLookup? componentLookup;

  /// `true` só no canvas do editor: ali o clique é da seleção do nó, então os
  /// gatilhos de gesto não ganham detector. Botão e formulário continuam
  /// despachando, e o editor avisa que a ação só roda no app cliente.
  final bool authoringMode;

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
  List<Widget> renderFlexChildren(BuildContext context, List<SduiNode> nodes) =>
      [
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

  void dispatchTrigger(SduiNode node, EventTrigger trigger) =>
      dispatch(node.events[trigger.name]);

  bool hasActions(SduiNode node, EventTrigger trigger) {
    final actions = node.events[trigger.name];
    return actions is List && actions.isNotEmpty;
  }

  Set<EventTrigger> boundGestureTriggers(SduiNode node) {
    if (onAction == null || authoringMode) return const {};
    final descriptor = descriptorFor(node.type);
    if (descriptor == null ||
        descriptor.declaresTrigger(EventTrigger.onPressed)) {
      return const {};
    }
    return {
      for (final trigger in descriptor.triggers)
        if (_gestureTriggers.contains(trigger) && hasActions(node, trigger))
          trigger,
    };
  }
}

const Set<EventTrigger> _gestureTriggers = {
  EventTrigger.onTap,
  EventTrigger.onDoubleTap,
  EventTrigger.onLongPress,
};

class _SduiNodeView extends StatelessWidget {
  const _SduiNodeView({required this.renderer, required this.node, super.key});

  final SduiRenderer renderer;
  final SduiNode node;

  @override
  Widget build(BuildContext context) {
    if (ComponentInstance.isInstance(node)) return _buildInstance(context);
    final builder = renderer.registry[node.type];
    final built = builder == null
        ? _UnknownTypeBox(type: node.type)
        : builder(
            context,
            resolveBoundProps(node, display: renderer.boundValueDisplay),
            renderer,
          );
    final triggers = renderer.boundGestureTriggers(node);
    final reactive = triggers.isEmpty
        ? built
        : SduiGestureTriggers(
            triggers: triggers,
            onTrigger: (trigger) => renderer.dispatchTrigger(node, trigger),
            child: built,
          );
    final wrapper = renderer.nodeWrapper;
    return wrapper == null ? reactive : wrapper(node, reactive);
  }

  Widget _buildInstance(BuildContext context) {
    final lookup = renderer.componentLookup;
    final Widget built;
    if (lookup == null) {
      built = const _ComponentErrorBox(
        message: 'Componente sem busca de componentes disponível',
      );
    } else {
      built = resolveComponentInstance(node, lookup).fold(
        (error) => _ComponentErrorBox(message: error.message),
        (resolved) => resolved == null
            ? const SizedBox.shrink()
            : renderer.render(context, resolved),
      );
    }
    final wrapper = renderer.nodeWrapper;
    return wrapper == null ? built : wrapper(node, built);
  }
}

class _ComponentErrorBox extends StatelessWidget {
  const _ComponentErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    developer.log(
      'Erro de componente: $message',
      name: 'sdui_flutter.renderer',
      level: 900,
    );
    if (!kDebugMode) return const SizedBox.shrink();
    return Container(
      padding: SduiChromeTokens.unknownTypePadding,
      decoration: BoxDecoration(
        border: Border.all(color: SduiChromeTokens.unknownTypeAccent),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: SduiChromeTokens.unknownTypeAccent,
          fontSize: SduiChromeTokens.unknownTypeFontSize,
        ),
      ),
    );
  }
}

class _UnknownTypeBox extends StatelessWidget {
  const _UnknownTypeBox({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    developer.log(
      'Tipo desconhecido: "$type"',
      name: 'sdui_flutter.renderer',
      level: 900,
    );
    if (!kDebugMode) return const SizedBox.shrink();
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
