import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_body.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Moldura de `VersionCompareDialog` no compacto (T5, item 50): ocupa a
/// tela inteira; previews e nós exclusivos viram controle segmentado em
/// vez de colunas espremidas — `VersionCompareBody(isCompact: true)`.
class VersionCompareFullscreenShell extends StatelessWidget {
  const VersionCompareFullscreenShell({this.imageUrlResolver, super.key});

  final SduiImageUrlResolver? imageUrlResolver;

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
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: VersionCompareBody(
            isCompact: true,
            imageUrlResolver: imageUrlResolver,
          ),
        ),
      ),
    );
  }
}
