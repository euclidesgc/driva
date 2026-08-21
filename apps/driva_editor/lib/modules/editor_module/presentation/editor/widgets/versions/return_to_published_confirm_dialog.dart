import 'package:flutter/material.dart';

/// Confirmação de `Voltar à versão publicada` (D6). Diálogo próprio, e não o
/// de carregar versão, porque a pergunta é outra: "voltar ao publicado", não
/// "carregar a vN" — e a resposta precisa dizer que a mudança é local até
/// `Salvar` e que `Ctrl+Z` desfaz.
class ReturnToPublishedConfirmDialog extends StatelessWidget {
  const ReturnToPublishedConfirmDialog({
    required this.publishedVersion,
    required this.isDirty,
    super.key,
  });

  final int publishedVersion;
  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Voltar à versão publicada (v$publishedVersion)?'),
      content: Text(
        isDirty
            ? 'O rascunho atual tem alterações não salvas. Voltar à versão '
                  'publicada substitui o rascunho só na sua sessão — nada é '
                  'publicado automaticamente, um Salvar depois ainda é '
                  'preciso para valer, e Ctrl+Z desfaz a volta.'
            : 'O rascunho local passa a ser idêntico à versão publicada '
                  'v$publishedVersion — só na sua sessão, até você usar '
                  'Salvar. Ctrl+Z desfaz a volta.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            isDirty
                ? 'Descartar alterações locais e voltar'
                : 'Voltar à versão publicada',
          ),
        ),
      ],
    );
  }
}
