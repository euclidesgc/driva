import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageErrorIcon extends StatelessWidget {
  const ImageErrorIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.broken_image_outlined,
      size: SduiChromeTokens.imageStateIconSize,
      color: SduiChromeTokens.imageErrorIconColor,
    );
  }
}
