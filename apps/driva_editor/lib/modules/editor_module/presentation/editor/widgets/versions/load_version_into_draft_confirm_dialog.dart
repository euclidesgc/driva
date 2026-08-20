import 'package:flutter/material.dart';

/// Confirmação de `Carregar no rascunho` (T3, item 50): declara a origem (a
/// versão), que a troca fica só na memória local e que nada vai ao ar
/// sozinho. Com o rascunho sujo, a única saída destrutiva é descartar — não
/// existe `Salvar antes`, porque salvar e carregar em seguida sobrescreveria
/// o mesmo draft remoto de qualquer jeito (plano do item 50).
class LoadVersionIntoDraftConfirmDialog extends StatelessWidget {
  const LoadVersionIntoDraftConfirmDialog({
    required this.version,
    required this.isDirty,
    super.key,
  });

  final int version;
  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Carregar a versão $version no rascunho?'),
      content: Text(
        isDirty
            ? 'O rascunho atual tem alterações não salvas. Carregar a '
                  'versão $version substitui o rascunho só na sua sessão — '
                  'nada é publicado automaticamente, e um Salvar depois '
                  'ainda é preciso para valer.'
            : 'O rascunho local passa a ser o spec da versão $version — só '
                  'na sua sessão, até você usar Salvar. O que está '
                  'publicado não muda.',
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
                ? 'Descartar alterações locais e carregar'
                : 'Carregar no rascunho',
          ),
        ),
      ],
    );
  }
}
