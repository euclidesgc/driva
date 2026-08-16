import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageEmptyBox extends StatelessWidget {
  const ImageEmptyBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Imagem sem URL definida',
      child: const SizedBox(
        width: SduiChromeTokens.imageDefaultExtent,
        height: SduiChromeTokens.imageDefaultExtent,
        child: ColoredBox(
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
