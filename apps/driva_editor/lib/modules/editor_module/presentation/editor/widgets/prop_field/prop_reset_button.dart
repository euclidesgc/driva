import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/theme/prop_icons.dart';
import 'package:flutter/material.dart';

/// Remove a chave do spec: o renderer volta a aplicar o default do catálogo.
class PropResetButton extends StatelessWidget {
  const PropResetButton({required this.onPressed, super.key});

  static const _size = 22.0;
  static const _iconSize = 14.0;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Tooltip(
      message: 'Voltar ao padrão',
      child: Semantics(
        button: true,
        label: 'Voltar ao padrão',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.r4),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              PropIcons.resolve('resetToDefault'),
              size: _iconSize,
              color: colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
