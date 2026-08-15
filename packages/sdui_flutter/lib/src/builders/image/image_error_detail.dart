import 'package:flutter/material.dart';

import 'package:sdui_flutter/src/builders/image/image_error_icon.dart';
import 'package:sdui_flutter/src/theme/sdui_chrome_tokens.dart';

class ImageErrorDetail extends StatelessWidget {
  const ImageErrorDetail({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ImageErrorIcon(),
        const SizedBox(height: SduiChromeTokens.imageStateGap),
        Text(
          reason,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SduiChromeTokens.imageErrorTextColor,
            fontSize: SduiChromeTokens.imageStateFontSize,
          ),
        ),
      ],
    );
  }
}
