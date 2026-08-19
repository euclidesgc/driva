import 'package:flutter/material.dart';

/// Confirmação isolada porque despublicar tira o conteúdo do ar na hora —
/// reversível (basta publicar de novo), mas ninguém deveria clicar sem
/// perceber o efeito.
class UnpublishConfirmDialog extends StatelessWidget {
  const UnpublishConfirmDialog({required this.versionsCount, super.key});

  final int versionsCount;

  String get _historyMessage => versionsCount == 1
      ? 'A única versão publicada continua guardada'
      : 'As $versionsCount versões publicadas continuam guardadas';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Despublicar conteúdo?'),
      content: Text(
        'Ele deixa de ficar visível para quem consome a API pública agora '
        'mesmo. $_historyMessage — publicar de novo é só um clique.',
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
