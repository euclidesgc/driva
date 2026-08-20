import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_body.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Moldura de `VersionReviewDialog` no desktop: `AlertDialog` largo o
/// bastante para o snapshot não parecer um recorte do canvas real.
class VersionReviewWindowedShell extends StatelessWidget {
  const VersionReviewWindowedShell({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Revisar versão'),
      content: SizedBox(
        width: AppSizes.versionReviewDialogWidth,
        height: AppSizes.versionSnapshotPreviewHeight + AppSpacing.s64,
        child: VersionReviewBody(imageUrlResolver: imageUrlResolver),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
