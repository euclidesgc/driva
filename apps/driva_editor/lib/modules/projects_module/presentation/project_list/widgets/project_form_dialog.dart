import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../../../core/error/error.dart';
import '../../../../../core/theme/editor_colors.dart';
import '../../../domain/entities/entities.dart';
import 'image_drop_zone.dart';
import 'image_picker.dart';

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
    this.onDelete,
  });

  final String title;
  final String? initialTitle;
  final String? initialDescription;

  /// URL da imagem atual (modo editar); `null` quando o projeto não tem uma.
  final String? initialImageUrl;

  final Future<Either<Failure, Project>> Function(ProjectFormResult form)
  onSubmit;

  /// Presente só no modo editar: exclui o projeto. `null` esconde a ação.
  final Future<Either<Failure, Unit>> Function()? onDelete;

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

  Future<void> _confirmDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: Text(
          '"${widget.initialTitle}" será excluído. Essa ação não tem volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await onDelete();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        // 409 (Restrict — projeto com conteúdos) chega aqui com a mensagem
        // da própria Failure, sem mensagem genérica de erro.
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
                  _ErrorBanner(message: _errorMessage!),
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
                _CoverPicker(
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
      actions: [
        if (widget.onDelete != null)
          TextButton.icon(
            onPressed: _submitting ? null : _confirmDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Excluir',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
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
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.image,
    required this.currentImageUrl,
    required this.hovering,
    required this.onPick,
    required this.onClear,
  });

  final ProjectImageInput? image;
  final String? currentImageUrl;
  final bool hovering;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final hasPreview = image != null || currentImageUrl != null;

    return Semantics(
      button: true,
      label: hasPreview
          ? 'Trocar imagem de capa do projeto'
          : 'Arraste uma imagem de capa ou clique para escolher um arquivo',
      child: Tooltip(
        message: 'Formatos aceitos: PNG, JPG, WEBP',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPick,
          child: Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hovering ? theme.colorScheme.primary : colors.border,
                    width: hovering ? 2 : 1,
                  ),
                  color: colors.panelAlt,
                ),
                child: hasPreview
                    ? _CoverPreview(
                        image: image,
                        currentImageUrl: currentImageUrl,
                      )
                    : _CoverPlaceholder(hovering: hovering),
              ),
              if (onClear != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: 'Remover imagem',
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.image, required this.currentImageUrl});

  final ProjectImageInput? image;
  final String? currentImageUrl;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image.memory(
        const WebImagePicker().bytesOf(image!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.network(
      currentImageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.hovering});

  final bool hovering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: hovering ? theme.colorScheme.primary : colors.inkMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Arraste uma imagem de capa\nou clique para escolher',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Aviso de erro do formulário: ícone + texto (a cor não é o único sinal).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Erro: $message',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
