import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// O spec da versão comparada dentro da moldura da direita, sem parecer
/// editável: `AbsorbPointer` barra toque e clique antes de chegarem ao
/// `SduiView`, e `FocusScope(canRequestFocus: false)` propaga para todo
/// descendente — Tab nunca foca um campo do snapshot. Sem `nodeWrapper` (o
/// que injetaria seleção e arraste) e sem `onAction`: nada aqui é acionável,
/// e soltar um widget da paleta sobre este lado não pode alterar o rascunho.
class VersionCompareInertPreview extends StatelessWidget {
  const VersionCompareInertPreview({
    required this.spec,
    this.imageUrlResolver,
    super.key,
  });

  final ContentSpec spec;
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      canRequestFocus: false,
      child: AbsorbPointer(
        child: SingleChildScrollView(
          child: SduiView.content(spec, imageUrlResolver: imageUrlResolver),
        ),
      ),
    );
  }
}
