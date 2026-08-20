import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Pede a nota do ponto que o save vai marcar no histórico.
///
/// A nota é obrigatória aqui, e não opcional como no contrato do servidor:
/// um ponto sem nota fica indistinguível de qualquer outro save quando o
/// usuário voltar ao histórico procurando por ele — que é justamente o que
/// marcar um ponto deveria evitar.
class SaveCheckpointDialog extends StatefulWidget {
  const SaveCheckpointDialog({super.key});

  @override
  State<SaveCheckpointDialog> createState() => _SaveCheckpointDialogState();
}

class _SaveCheckpointDialogState extends State<SaveCheckpointDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salvar e marcar no histórico'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          const Text(
            'O ponto marcado fica no histórico para você voltar a ele, mas '
            'não vai ao ar: só publicar coloca conteúdo no aplicativo.',
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'O que este ponto guarda',
              hintText: 'antes de trocar o banner da home',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _confirm,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => _confirm(_controller.text),
          child: const Text('Salvar e marcar'),
        ),
      ],
    );
  }

  void _confirm(String value) {
    final note = value.trim();
    if (note.isEmpty) return;
    Navigator.of(context).pop(note);
  }
}
