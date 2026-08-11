import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// `null` em [onChanged] remove a chave (volta ao default do renderer).
///
/// A key do campo vem do Inspector (`nodeId_fieldKey`), nunca do valor: pelo
/// valor, o campo é recriado a cada tecla e o foco se perde.
class PropFieldEditor extends StatelessWidget {
  const PropFieldEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  bool get _isBound => SduiBinding.isBinding(value);

  Future<void> _editBinding(BuildContext context) async {
    final expression = await showDialog<String>(
      context: context,
      builder: (_) => PropBindingDialog(
        propLabel: field.label,
        kind: field.kind,
        initialExpression: SduiBinding.expressionOf(value),
      ),
    );
    if (expression == null) return;
    onChanged(SduiBinding.wrap(expression));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final expression = SduiBinding.expressionOf(value);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: TextStyle(
                  fontSize: AppTypography.md,
                  color: colors.inkSecondary,
                ),
              ),
              if (field.isRequired)
                const Text(' *', style: TextStyle(color: AppTheme.primary)),
              const Spacer(),
              if (field.isBindable)
                PropBindingButton(
                  isActive: _isBound,
                  onPressed: () => _editBinding(context),
                ),
              if (value != null && !field.isRequired && !_isBound)
                PropResetButton(onPressed: () => onChanged(null)),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          if (expression != null)
            PropBindingEditor(
              expression: expression,
              onClear: () => onChanged(null),
            )
          else
            TypedPropEditor(
              field: field,
              value: value,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
