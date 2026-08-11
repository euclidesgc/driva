import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Devolve a expressão (sem chaves) ou `null` se o usuário cancelar. String
/// vazia significa "voltar a valor fixo".
class PropBindingDialog extends StatefulWidget {
  const PropBindingDialog({
    required this.propLabel,
    required this.kind,
    this.initialExpression,
    super.key,
  });

  final String propLabel;
  final FieldKind kind;
  final String? initialExpression;

  @override
  State<PropBindingDialog> createState() => _PropBindingDialogState();
}

class _PropBindingDialogState extends State<PropBindingDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialExpression ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return AlertDialog(
      title: Text('Definir “${widget.propLabel}” por variável'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo esperado: ${_kindLabel(widget.kind)}',
            style: TextStyle(
              fontSize: AppTypography.sm,
              color: colors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Expressão',
              hintText: 'usuario.nome',
              prefixText: '{{',
              suffixText: '}}',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'O editor guarda a expressão como dado; quem resolve o valor é o '
            'app cliente.',
            style: TextStyle(
              fontSize: AppTypography.xs,
              color: colors.inkMuted,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.initialExpression != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Voltar a valor fixo'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  static String _kindLabel(FieldKind kind) => switch (kind) {
    FieldKind.string => 'texto',
    FieldKind.doubleNum => 'número',
    FieldKind.intNum => 'número inteiro',
    FieldKind.boolean => 'booleano',
    FieldKind.color => 'cor',
    FieldKind.enumeration => 'opção',
    FieldKind.edgeInsets => 'espaçamento',
    FieldKind.alignment => 'alinhamento',
    FieldKind.iconName => 'ícone',
  };
}
