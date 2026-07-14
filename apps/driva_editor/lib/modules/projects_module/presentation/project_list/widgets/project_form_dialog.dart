import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../../../core/error/error.dart';
import '../../../../../core/theme/editor_colors.dart';
import '../../../../../core/widgets/feedback/feedback.dart';
import '../../../domain/entities/entities.dart';
import 'image_drop_zone.dart';
import 'image_picker.dart';
import 'project_form/project_form.dart';

typedef ProjectFormResult = ({
  String title,
  String? description,
  ProjectImageInput? image,
  bool removeImage,
});

/// Formulário de criar/editar projeto (modal), espelhando o protótipo:
/// capa com drag-and-drop/click, título, descrição.
class ProjectFormDialog extends StatefulWidget {
  const ProjectFormDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialTitle,
    this.initialDescription,
    this.initialImageUrl,
    this.onArchive,
  });

  final String title;
  final String? initialTitle;
  final String? initialDescription;

  /// URL da imagem atual (modo editar); `null` quando o projeto não tem uma.
  final String? initialImageUrl;

  final Future<Either<Failure, Project>> Function(ProjectFormResult form)
  onSubmit;

  /// Presente só no modo editar: arquiva o projeto (exclusão lógica — ele
  /// some da home mas não é apagado; fica acessível em "Arquivados").
  /// `null` esconde a ação.
  final Future<Either<Failure, Project>> Function()? onArchive;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;

  ProjectImageInput? _newImage;
  bool _removeImage = false;
  bool _dropHovering = false;
  bool _submitting = false;
  String? _errorMessage;

  WebImageDropZone? _dropZone;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _description = TextEditingController(text: widget.initialDescription ?? '');
    _dropZone = WebImageDropZone(
      onHover: (hovering) {
        if (!mounted) return;
        setState(() => _dropHovering = hovering);
      },
      onFile: (image) {
        if (!mounted) return;
        setState(() {
          _newImage = image;
          _removeImage = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _dropZone?.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _hasCurrentImage =>
      widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty;

  static const _imagePicker = WebImagePicker();

  Future<void> _pickImage() async {
    final image = await _imagePicker.pick();
    if (image == null || !mounted) return;
    setState(() {
      _newImage = image;
      _removeImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _newImage = null;
      _removeImage = true;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final description = _description.text.trim();
    final result = await widget.onSubmit((
      title: _title.text.trim(),
      description: description.isEmpty ? null : description,
      image: _newImage,
      removeImage: _removeImage,
    ));
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _errorMessage = _messageFor(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Projeto não encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado. Tente de novo.',
  };

  Future<void> _confirmArchive() async {
    final onArchive = widget.onArchive;
    if (onArchive == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arquivar projeto?'),
        content: Text(
          '"${widget.initialTitle}" sai da lista de projetos, mas nada é '
          'apagado — você pode restaurá-lo a qualquer momento em '
          '"Arquivados".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await onArchive();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _errorMessage = _messageFor(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  MessageBanner(
                    message: _errorMessage!,
                    semanticsPrefix: 'Erro',
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'CAPA',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.inkMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                CoverPicker(
                  image: _newImage,
                  currentImageUrl: _hasCurrentImage && !_removeImage
                      ? widget.initialImageUrl
                      : null,
                  hovering: _dropHovering,
                  onPick: _pickImage,
                  onClear:
                      (_newImage != null || _hasCurrentImage) && !_removeImage
                      ? _clearImage
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Nome do projeto',
                  ),
                  validator: (value) {
                    final title = (value ?? '').trim();
                    if (title.isEmpty) return 'Informe o título.';
                    if (title.length > 120) {
                      return 'Use até 120 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Uma breve descrição do projeto',
                  ),
                  validator: (value) {
                    final description = (value ?? '').trim();
                    if (description.length > 280) {
                      return 'Use até 280 caracteres.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      // `actions` do AlertDialog vão para um OverflowBar (não é um Flex), então
      // Spacer/Expanded ali estoura ("ParentDataWidget"). Para empurrar
      // "Arquivar" à esquerda, usamos actionsAlignment e agrupamos
      // Cancelar/Salvar num Row.
      actionsAlignment: widget.onArchive != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      actions: [
        if (widget.onArchive != null)
          TextButton.icon(
            onPressed: _submitting ? null : _confirmArchive,
            icon: Icon(
              Icons.archive_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Arquivar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar projeto'),
            ),
          ],
        ),
      ],
    );
  }
}
