import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/core/widgets/layout/layout.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter/material.dart';

/// `note` não-nulo distingue "confirmou sem nota" de "cancelou" — o segundo
/// nunca chega a devolver um `PublishDialogResult`, só `null` puro.
typedef PublishDialogResult = ({String? note});

/// Confirmação antes de publicar: mostra a versão que nasce, a contagem de
/// avisos não bloqueantes do documento e o campo de nota opcional (mesmo
/// limite de 200 chars do `PublishContentDto`).
class PublishDialog extends StatefulWidget {
  const PublishDialog({
    required this.publication,
    required this.warningsCount,
    super.key,
  });

  final PublicationState publication;
  final int warningsCount;

  @override
  State<PublishDialog> createState() => _PublishDialogState();
}

class _PublishDialogState extends State<PublishDialog> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _note.text.trim();
    Navigator.of(
      context,
    ).pop<PublishDialogResult>((note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final nextVersion = (widget.publication.publishedVersion ?? 0) + 1;
    return AlertDialog(
      title: const Text('Publicar conteúdo'),
      content: DialogContentWidth(
        maxWidth: AppSizes.formDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.publication.hasUnpublishedChanges
                  ? 'Isso cria a versão $nextVersion e coloca ela no ar.'
                  : 'Sem mudança desde a última publicação — confirma manter '
                        'a v${widget.publication.publishedVersion} no ar.',
            ),
            if (widget.warningsCount > 0) ...[
              const SizedBox(height: AppSpacing.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppIconSizes.s18,
                    color: colors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      widget.warningsCount == 1
                          ? '1 aviso não bloqueante neste documento — não '
                                'impede publicar.'
                          : '${widget.warningsCount} avisos não bloqueantes '
                                'neste documento — não impedem publicar.',
                      style: TextStyle(
                        fontSize: AppTypography.sm,
                        color: colors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _note,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'O que mudou nesta versão?',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Publicar')),
      ],
    );
  }
}
