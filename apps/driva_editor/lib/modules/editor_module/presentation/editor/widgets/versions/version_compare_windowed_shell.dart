import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_body.dart';
import 'package:flutter/material.dart';

/// Moldura de `VersionCompareDialog` no desktop: `AlertDialog` largo o
/// bastante para a seção de nós exclusivos caber em duas colunas sem
/// espremer texto (T5, item 50).
class VersionCompareWindowedShell extends StatelessWidget {
  const VersionCompareWindowedShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comparar versão'),
      content: const SizedBox(
        width: AppSizes.versionCompareDialogWidth,
        height: AppSizes.versionCompareDialogMaxHeight,
        child: VersionCompareBody(isCompact: false),
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
