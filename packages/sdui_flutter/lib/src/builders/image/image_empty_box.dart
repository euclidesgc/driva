import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageEmptyBox extends StatelessWidget {
  const ImageEmptyBox({this.width, this.height, super.key});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Imagem sem URL definida',
      child: SizedBox(
        width: width ?? SduiChromeTokens.imageDefaultExtent,
        height: height ?? SduiChromeTokens.imageDefaultExtent,
        child: const ColoredBox(
          color: SduiChromeTokens.imageEmptyBackground,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: SduiChromeTokens.imageStateIconSize,
              color: SduiChromeTokens.imageEmptyIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
