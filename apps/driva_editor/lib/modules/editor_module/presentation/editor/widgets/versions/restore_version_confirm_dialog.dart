import 'package:flutter/material.dart';

/// Restaurar descarta o rascunho atual sem aviso — por isso a etapa própria
/// de confirmação (D4 do plano do item 24), separada de fechar o histórico.
class RestoreVersionConfirmDialog extends StatelessWidget {
  const RestoreVersionConfirmDialog({required this.version, super.key});

  final int version;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Restaurar a versão $version?'),
      content: const Text(
        'O rascunho atual é substituído pelo spec desta versão. O que está '
        'publicado não muda até você publicar de novo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Restaurar'),
        ),
      ],
    );
  }
}
