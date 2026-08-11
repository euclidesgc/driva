import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

class PropBindingButton extends StatelessWidget {
  const PropBindingButton({
    required this.isActive,
    required this.onPressed,
    super.key,
  });

  static const _size = 22.0;
  static const _iconSize = 14.0;

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label = isActive ? 'Editar variável' : 'Definir por variável';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.r4),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              Icons.data_object,
              size: _iconSize,
              color: isActive ? AppTheme.primary : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
