import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/category.dart';

typedef CategoryFormResult = ({String name, String? parentId});

/// Form modal de categoria (nome + categoria-pai), fiel ao `.dc.html`
/// (`isCatForm`): usado tanto para criar quanto para editar.
///
/// [excludeIds] impede escolher a própria categoria (ou um descendente dela)
/// como pai — evitaria um ciclo na árvore.
class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    required this.title,
    required this.availableParents,
    this.initialName,
    this.initialParentId,
    this.excludeIds = const {},
  });

  final String title;
  final List<Category> availableParents;
  final String? initialName;
  final String? initialParentId;
  final Set<String> excludeIds;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _parentId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _parentId = widget.initialParentId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((name: _name.text.trim(), parentId: _parentId));
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.availableParents
        .where((c) => !widget.excludeIds.contains(c.id))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da categoria',
                  hintText: 'Ex.: Notícias',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String?>(
                initialValue: _parentId,
                decoration: const InputDecoration(labelText: 'Categoria pai'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nenhuma (raiz)'),
                  ),
                  for (final category in options)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _parentId = value),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Deixe em "Nenhuma (raiz)" para uma categoria de topo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar categoria')),
      ],
    );
  }
}
