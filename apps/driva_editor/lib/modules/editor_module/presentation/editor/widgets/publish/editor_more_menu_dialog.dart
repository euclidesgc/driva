import 'package:driva_editor/core/theme/theme.dart';
import 'package:flutter/material.dart';

enum EditorMoreMenuChoice { versionHistory, unpublish }

/// Menu "mais opções" do topo do editor: despublicar mora aqui, atrás de um
/// clique — nunca no botão principal (decisão do humano, item 24 §8).
class EditorMoreMenuDialog extends StatelessWidget {
  const EditorMoreMenuDialog({required this.isPublished, super.key});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Mais opções'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(
            context,
          ).pop(EditorMoreMenuChoice.versionHistory),
          child: const Row(
            children: [
              Icon(Icons.history, size: AppIconSizes.s18),
              SizedBox(width: AppSpacing.s12),
              Text('Ver histórico de versões'),
            ],
          ),
        ),
        if (isPublished)
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(EditorMoreMenuChoice.unpublish),
            child: const Row(
              children: [
                Icon(Icons.visibility_off_outlined, size: AppIconSizes.s18),
                SizedBox(width: AppSpacing.s12),
                Text('Despublicar'),
              ],
            ),
          ),
      ],
    );
  }
}
