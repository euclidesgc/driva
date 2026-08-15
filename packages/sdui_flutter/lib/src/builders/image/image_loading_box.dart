import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageLoadingBox extends StatelessWidget {
  const ImageLoadingBox({this.width, this.height, super.key});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando imagem',
      child: SizedBox(
        width: width ?? SduiChromeTokens.imageDefaultExtent,
        height: height ?? SduiChromeTokens.imageDefaultExtent,
        child: const ColoredBox(
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
