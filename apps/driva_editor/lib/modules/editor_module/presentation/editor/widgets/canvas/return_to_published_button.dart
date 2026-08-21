import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';

/// O reset pedido pelo dono (D6): deixa o rascunho idêntico à versão
/// publicada. Só é montado durante o modo de comparação e quando existe
/// versão publicada — botão que não pode agir não existe.
class ReturnToPublishedButton extends StatelessWidget {
  const ReturnToPublishedButton({
    required this.onPressed,
    this.collapsed = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return IconButton(
        tooltip: 'Voltar à versão publicada',
        iconSize: AppIconSizes.s18,
        icon: const Icon(Icons.settings_backup_restore),
        onPressed: onPressed,
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.settings_backup_restore, size: AppIconSizes.s18),
      label: const Text('Voltar à versão publicada'),
    );
  }
}
