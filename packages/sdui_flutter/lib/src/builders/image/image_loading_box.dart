import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageLoadingBox extends StatelessWidget {
  const ImageLoadingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando imagem',
      child: const SizedBox(
        width: SduiChromeTokens.imageDefaultExtent,
        height: SduiChromeTokens.imageDefaultExtent,
        child: ColoredBox(
          color: SduiChromeTokens.imageLoadingBackground,
          child: Center(
            child: SizedBox(
              width: SduiChromeTokens.imageStateIconSize,
              height: SduiChromeTokens.imageStateIconSize,
              child: CircularProgressIndicator(
                strokeWidth: SduiChromeTokens.imageLoadingStrokeWidth,
                color: SduiChromeTokens.imageLoadingIndicatorColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
