import 'package:flutter/material.dart';

/// Confirmação isolada porque despublicar tira o conteúdo do ar na hora —
/// reversível (basta publicar de novo), mas ninguém deveria clicar sem
/// perceber o efeito.
class UnpublishConfirmDialog extends StatelessWidget {
  const UnpublishConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Despublicar conteúdo?'),
      content: const Text(
        'Ele deixa de ficar visível para quem consome a API pública agora '
        'mesmo. O histórico de versões continua guardado — publicar de novo '
        'é só um clique.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Despublicar'),
        ),
      ],
    );
  }
}
