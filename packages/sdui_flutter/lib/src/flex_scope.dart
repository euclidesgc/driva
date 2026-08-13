import 'package:flutter/widgets.dart';

/// Diz se o nó está **diretamente** dentro de um `Row`/`Column`.
///
/// `Expanded` é um `ParentDataWidget`: fora de um flex ele não desenha errado —
/// ele **derruba a árvore** com erro de ParentData. No editor o usuário solta o
/// widget onde quiser, então o builder precisa saber onde está.
///
/// O escopo é reafirmado a cada nível (inclusive como `false`): sem isso, um
/// neto dentro de um `Container` continuaria enxergando o flex do avô.
/// `InheritedWidget` não é `RenderObjectWidget`, logo não se interpõe entre o
/// `Flex` e o `Expanded`.
class SduiFlexScope extends InheritedWidget {
  const SduiFlexScope({
    required this.isFlexParent,
    required super.child,
    super.key,
  });

  final bool isFlexParent;

  static bool isInFlex(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SduiFlexScope>()
          ?.isFlexParent ??
      false;

  @override
  bool updateShouldNotify(SduiFlexScope oldWidget) =>
      isFlexParent != oldWidget.isFlexParent;
}
