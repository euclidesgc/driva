import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Renderiza o spec histórico sem deixá-lo parecer editável (T3, item 50):
/// `AbsorbPointer` barra toque/clique antes de chegarem ao `SduiView`, e
/// `FocusScope(canRequestFocus: false)` propaga para todo descendente — Tab
/// nunca foca um campo do snapshot, e sem foco nenhum widget abre conexão de
/// teclado. `onAction` fica `null` de propósito: nada aqui é acionável.
class VersionSnapshotPreview extends StatelessWidget {
  const VersionSnapshotPreview({
    required this.spec,
    this.imageUrlResolver,
    super.key,
  });

  final ContentSpec spec;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.canvasBackdrop,
        borderRadius: BorderRadius.circular(AppRadii.r8),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: FocusScope(
        canRequestFocus: false,
        child: AbsorbPointer(
          child: SingleChildScrollView(
            child: SduiView.content(spec, imageUrlResolver: imageUrlResolver),
          ),
        ),
      ),
    );
  }
}
