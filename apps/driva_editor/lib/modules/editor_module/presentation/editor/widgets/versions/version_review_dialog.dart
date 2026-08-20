import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_fullscreen_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_windowed_shell.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Diálogo de revisão de uma versão histórica (T3, item 50): amplo no
/// desktop, tela cheia no compacto — nos dois casos o conteúdo
/// (`VersionReviewBody`) é o mesmo, só a moldura muda, para o snapshot nunca
/// ficar espremido.
class VersionReviewDialog extends StatelessWidget {
  const VersionReviewDialog({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width < AppSizes.versionReviewDialogFitWidth;
    return isCompact
        ? VersionReviewFullscreenShell(imageUrlResolver: imageUrlResolver)
        : VersionReviewWindowedShell(imageUrlResolver: imageUrlResolver);
  }
}
