import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_body.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Moldura de `VersionReviewDialog` no compacto: ocupa a tela inteira em vez
/// de espremer o snapshot num `AlertDialog` estreito.
class VersionReviewFullscreenShell extends StatelessWidget {
  const VersionReviewFullscreenShell({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Revisar versão'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: VersionReviewBody(imageUrlResolver: imageUrlResolver),
        ),
      ),
    );
  }
}
