import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/category.dart';

/// Form modal de "mover conteúdo": só o seletor de categoria-destino, fiel
/// ao `.dc.html` (ícone dedicado `onMove` no card/linha, separado de
/// "editar"). Devolve o `categoryId` escolhido, ou `null` se cancelado.
///
/// Sem opção "Não categorizado": todo conteúdo sempre tem uma categoria (a
/// "Geral" é o default do backend quando a escrita omite `categoryId`) — e
/// o contrato de update **omite** a chave quando `categoryId` é nulo (não
/// limpa a categoria), então oferecer essa opção aqui seria uma ação que
/// parece mover mas não move nada.
class MoveContentDialog extends StatefulWidget {
  const MoveContentDialog({
    super.key,
    required this.contentName,
    required this.categories,
    required this.currentCategoryId,
  });

  final String contentName;
  final List<Category> categories;
  final String currentCategoryId;

  @override
  State<MoveContentDialog> createState() => _MoveContentDialogState();
}

class _MoveContentDialogState extends State<MoveContentDialog> {
  late String _categoryId = widget.currentCategoryId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mover "${widget.contentName}"'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a categoria de destino.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _categoryId = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _categoryId == widget.currentCategoryId
              ? null
              : () => Navigator.of(context).pop(_categoryId),
          child: const Text('Mover'),
        ),
      ],
    );
  }
}
