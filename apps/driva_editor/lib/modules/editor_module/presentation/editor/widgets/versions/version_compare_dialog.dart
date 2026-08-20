import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_fullscreen_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_windowed_shell.dart';
import 'package:flutter/material.dart';

/// Diálogo de comparação de uma versão histórica com o rascunho (T5, item
/// 50): amplo no desktop, tela cheia no compacto — mesmo padrão de
/// `VersionReviewDialog` (T3), com um limiar próprio porque a composição é
/// mais densa (duas colunas de nós exclusivos).
class VersionCompareDialog extends StatelessWidget {
  const VersionCompareDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width <
        AppSizes.versionCompareDialogFitWidth;
    return isCompact
        ? const VersionCompareFullscreenShell()
        : const VersionCompareWindowedShell();
  }
}
