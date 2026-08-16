import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/builders/image/image_error_detail.dart';
import 'package:sdui_flutter/src/builders/image/image_error_icon.dart';
import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

/// [src] só chega preenchido quando o renderer está em modo diagnóstico (o
/// editor) — no app publicado ele é `null` e nunca aparece no `Tooltip`/
/// `Semantics`, para não vazar URL (possivelmente assinada) ao usuário final.
class ImageErrorBox extends StatelessWidget {
  const ImageErrorBox({required this.reason, this.src, super.key});

  final String reason;
  final String? src;

  @override
  Widget build(BuildContext context) {
    final url = src;
    final detail = url == null
        ? 'Falha ao carregar imagem: $reason'
        : 'Falha ao carregar imagem: $reason — $url';

    return Tooltip(
      message: detail,
      excludeFromSemantics: true,
      child: Semantics(
        label: detail,
        child: Container(
          width: SduiChromeTokens.imageDefaultExtent,
          height: SduiChromeTokens.imageDefaultExtent,
          padding: SduiChromeTokens.imageStatePadding,
          decoration: BoxDecoration(
            color: SduiChromeTokens.imageErrorBackground,
            border: Border.all(
              color: SduiChromeTokens.imageErrorBorderColor,
              width: SduiChromeTokens.imageErrorBorderWidth,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  constraints.maxHeight >=
                      SduiChromeTokens.imageErrorTextMinHeight
                  ? ImageErrorDetail(reason: reason)
                  : const ImageErrorIcon(),
            ),
          ),
        ),
      ),
    );
  }
}
