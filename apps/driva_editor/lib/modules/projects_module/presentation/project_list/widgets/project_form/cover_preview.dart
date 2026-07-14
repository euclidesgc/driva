import 'package:flutter/material.dart';

import '../../../../domain/entities/entities.dart';
import '../image_picker.dart';

class CoverPreview extends StatelessWidget {
  const CoverPreview({
    super.key,
    required this.image,
    required this.currentImageUrl,
  });

  final ProjectImageInput? image;
  final String? currentImageUrl;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image.memory(
        const WebImagePicker().bytesOf(image!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.network(
      currentImageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
