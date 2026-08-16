import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/last_saved_pill.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart' show ContentSpec;
import 'package:sdui_flutter/sdui_flutter.dart';

/// A tela do preview: o conteúdo desenhado pelo renderer real, sem seleção de
/// nó (`nodeWrapper` ausente) e sem diagnósticos — `SduiView.content` já nasce
/// com `showDiagnostics: false` por padrão, e é isso que a D17 pede: visual,
/// não interativo, sem vazar detalhe de infraestrutura para quem recebe o
/// link. A pílula da D4 flutua no rodapé.
class PreviewContent extends StatelessWidget {
  const PreviewContent({
    required this.spec,
    required this.fetchedAt,
    required this.onReload,
    this.imageUrlResolver,
    super.key,
  });

  final ContentSpec spec;
  final DateTime fetchedAt;
  final VoidCallback onReload;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: SduiView.content(spec, imageUrlResolver: imageUrlResolver),
          ),
        ),
        Positioned(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          bottom: AppSpacing.s16,
          child: Center(
            child: LastSavedPill(fetchedAt: fetchedAt, onReload: onReload),
          ),
        ),
      ],
    );
  }
}
