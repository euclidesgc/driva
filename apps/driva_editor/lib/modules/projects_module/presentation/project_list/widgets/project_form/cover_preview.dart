import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/image_picker.dart';
import 'package:flutter/material.dart';

class CoverPreview extends StatelessWidget {
  const CoverPreview({
    required this.image,
    required this.currentImageUrl,
    super.key,
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
