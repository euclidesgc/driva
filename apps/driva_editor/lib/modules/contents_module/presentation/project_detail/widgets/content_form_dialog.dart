import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/util/slug.dart';
import '../../../../../core/widgets/feedback/feedback.dart';
import '../../../domain/entities/category.dart';

typedef ContentFormResult = ({
  String name,
  String slug,
  String? description,
  String? categoryId,
});

/// Form modal de conteúdo (nome/slug/descrição + categoria), fiel ao
/// `.dc.html` (`isContentForm`). `defaultCategoryId` é o nó selecionado na
/// árvore no momento em que o form abriu.
class ContentFormDialog extends StatefulWidget {
  const ContentFormDialog({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.categories,
    required this.existingSlugs,
    this.initialName,
    this.initialSlug,
    this.initialDescription,
    this.defaultCategoryId,
    this.conflictMessage,
  });

  final String title;
  final String saveLabel;
  final List<Category> categories;
  final Set<String> existingSlugs;
  final String? initialName;
  final String? initialSlug;
  final String? initialDescription;
  final String? defaultCategoryId;
  final String? conflictMessage;

  @override
  State<ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<ContentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  String? _categoryId;

  bool _slugTouched = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _slug = TextEditingController(text: widget.initialSlug ?? '');
    _description = TextEditingController(text: widget.initialDescription ?? '');
    _categoryId = widget.defaultCategoryId;
    _slugTouched = (widget.initialSlug ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_slugTouched) return;
    setState(() {
      _slug.text = SlugUtil.suggestFree(
        SlugUtil.slugify(value),
        widget.existingSlugs,
      );
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _description.text.trim();
    Navigator.of(context).pop((
      name: _name.text,
      slug: _slug.text.trim(),
      description: description.isEmpty ? null : description,
      categoryId: _categoryId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              if (widget.conflictMessage != null) ...[
                MessageBanner(message: widget.conflictMessage!),
                const SizedBox(height: AppSpacing.s12),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Home — vitrine',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                onChanged: _onNameChanged,
              ),
              const SizedBox(height: AppSpacing.s12),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Slug — referência no código',
                  prefixIcon: Icon(Icons.tag),
                  helperText:
                      'O slug é sua referência no código; mudá-lo depois '
                      'quebra apps que já o usam.',
                  helperMaxLines: 2,
                ),
                onChanged: (_) => _slugTouched = true,
                validator: (value) {
                  final slug = (value ?? '').trim();
                  if (slug.isEmpty) return 'Informe o slug.';
                  if (!SlugUtil.isValid(slug)) {
                    return 'Use letras minúsculas, números e hifens '
                        '(começando por letra).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Para que serve este conteúdo?',
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Não categorizado'),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'ID de suporte é gerado pelo servidor após criar.',
                style: theme.textTheme.bodySmall,
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
        FilledButton(onPressed: _submit, child: Text(widget.saveLabel)),
      ],
    );
  }
}
