import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_body.dart';
import 'package:flutter/material.dart';

/// Moldura de `VersionCompareDialog` no compacto (T5, item 50): ocupa a
/// tela inteira, e a seção de nós exclusivos vira controle segmentado em
/// vez de duas colunas espremidas — `VersionCompareBody(isCompact: true)`.
class VersionCompareFullscreenShell extends StatelessWidget {
  const VersionCompareFullscreenShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparar versão'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: VersionCompareBody(isCompact: true),
        ),
      ),
    );
  }
}
