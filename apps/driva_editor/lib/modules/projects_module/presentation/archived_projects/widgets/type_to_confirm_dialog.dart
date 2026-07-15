import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_radii.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/editor_colors.dart';

/// Segunda etapa da confirmação dupla: exige digitar o título do projeto
/// para habilitar o botão de excluir — a barreira extra contra exclusão
/// definitiva por engano (ação irreversível, cascade total).
class TypeToConfirmDialog extends StatefulWidget {
  const TypeToConfirmDialog({super.key, required this.projectTitle});

  final String projectTitle;

  @override
  State<TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<TypeToConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyTitle(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.projectTitle));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nome copiado.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return AlertDialog(
      title: const Text('Confirmação final'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            label:
                'Aviso: esta ação não tem volta. Digite o nome do projeto '
                'para confirmar.',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.s8),
                const Expanded(
                  child: Text(
                    'Esta ação não tem volta. Digite o nome do projeto '
                    'para confirmar a exclusão definitiva.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Digite o nome do projeto para confirmar:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s6),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            decoration: BoxDecoration(
              color: colors.panelAlt,
              borderRadius: BorderRadius.circular(AppRadii.r8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    widget.projectTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Copiar nome do projeto',
                  child: IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    onPressed: () => _copyTitle(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nome do projeto'),
            onChanged: (value) =>
                setState(() => _matches = value.trim() == widget.projectTitle),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir definitivamente'),
        ),
      ],
    );
  }
}
