import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// A versão por-propriedade de "Trazer todas as propriedades desta versão"
/// do cabeçalho do Inspector (T5b.12, item 50): traz só o valor deste campo
/// da candidata comparada para o rascunho.
class PropVersionCopyButton extends StatelessWidget {
  const PropVersionCopyButton({required this.onPressed, super.key});

  static const _size = 22.0;
  static const _iconSize = 14.0;
  static const _label = 'Trazer o valor desta versão';

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: _label,
      child: Semantics(
        button: true,
        label: _label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.r4),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              Icons.arrow_back,
              size: _iconSize,
              color: colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
