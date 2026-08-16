import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// O `MaterialScrollBehavior` padrão não põe o mouse em `dragDevices`, e sem
/// isso o `RefreshIndicator` do preview só responde a toque. No Chrome do
/// desktop o gesto simplesmente não existiria — e como a D30 tirou o botão de
/// atualizar, sobraria recarregar a página inteira.
class PreviewScrollBehavior extends MaterialScrollBehavior {
  const PreviewScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
