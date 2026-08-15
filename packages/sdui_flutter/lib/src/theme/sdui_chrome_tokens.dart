import 'package:flutter/widgets.dart';

/// Chrome do renderer: o que não vem do spec SDUI, mas do próprio
/// `sdui_flutter` — placeholder de tipo desconhecido, estados do widget
/// `image`. O styling derivado das props do nó continua vindo do
/// catálogo/props, não daqui.
abstract final class SduiChromeTokens {
  static const Color unknownTypeAccent = Color(0xFFCC3333);
  static const double unknownTypeFontSize = 12;
  static const EdgeInsets unknownTypePadding = EdgeInsets.all(8);

  static const double imageDefaultExtent = 80;
  static const EdgeInsets imageStatePadding = EdgeInsets.all(6);
  static const double imageStateIconSize = 20;
  static const double imageStateFontSize = 11;
  static const double imageStateGap = 4;

  static const Color imageEmptyBackground = Color(0x14000000);

  /// `0x8A000000` (= `Colors.black54`) sobre o `#EBEBEB` composto do fundo
  /// vazio/carregando dá ~4,4:1 — a régua de contraste não-textual (WCAG
  /// 1.4.11) é 3:1. Ícone é o único portador do estado "sem URL"; abaixo
  /// disso ele deixa de ser lido como sinal e volta a ser só cinza.
  static const Color imageEmptyIconColor = Color(0x8A000000);

  static const Color imageLoadingBackground = Color(0x14000000);
  static const Color imageLoadingIndicatorColor = Color(0x8A000000);
  static const double imageLoadingStrokeWidth = 2;

  static const Color imageErrorBackground = Color(0x1AE53935);
  static const Color imageErrorBorderColor = Color(0xFFE53935);
  static const double imageErrorBorderWidth = 1.5;
  static const Color imageErrorIconColor = Color(0xFFE53935);
  static const Color imageErrorTextColor = Color(0xFFB71C1C);

  /// Altura mínima em que ícone + gap + duas linhas de texto a
  /// [imageStateFontSize] cabem dentro do padding sem estourar o `Column`
  /// (medido: 61px). Abaixo disso o estado "falhou" degrada para só ícone.
  static const double imageErrorTextMinHeight = 61;
}
