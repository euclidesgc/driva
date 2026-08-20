import 'package:flutter/material.dart';

/// A seta de cópia seletiva (T5, item 50): sempre aponta para o rascunho,
/// nunca para a candidata — a convenção travada pelo motor puro
/// (`copyComparableNodeProperties`, `packages/sdui_core`). `VersionCompareNodeRow`
/// só monta este widget quando o nó é mesmo compatível — ela nunca existe
/// como um botão desabilitado num nó que não pode ser copiado.
class VersionCompareCopyArrowButton extends StatelessWidget {
  const VersionCompareCopyArrowButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copiar as propriedades deste nó para o rascunho',
      child: Semantics(
        button: true,
        label: 'Copiar propriedades para o rascunho',
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
    );
  }
}
