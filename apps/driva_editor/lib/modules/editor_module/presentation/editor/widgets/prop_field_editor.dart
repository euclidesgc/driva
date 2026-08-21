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
    this.onCopyFromVersion,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Não nulo só quando o modo de comparação está ativo e este campo tem
  /// valor diferente na candidata (T5b.12, item 50) — quem decide é
  /// `PropFieldCompareBinding`, de propósito fora deste widget.
  final VoidCallback? onCopyFromVersion;

  /// Kinds cujo editor monta a própria moldura: precisam de um controle na
  /// linha do rótulo que compartilha estado com o corpo (a unidade do campo de
  /// dimensão, por exemplo), e o wrapper não tem como entregar isso de fora.
  static const Set<FieldKind> _selfChromed = {FieldKind.dimension};

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
    final expression = SduiBinding.expressionOf(value);
    final bindingButton = field.isBindable
        ? PropBindingButton(
            isActive: _isBound,
            onPressed: () => _editBinding(context),
          )
        : null;
    final resetButton = value != null && !field.isRequired && !_isBound
        ? PropResetButton(onPressed: () => onChanged(null))
        : null;
    final copyButton = onCopyFromVersion != null
        ? PropVersionCopyButton(onPressed: onCopyFromVersion!)
        : null;

    if (expression == null && _selfChromed.contains(field.kind)) {
      return SelfChromedPropEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        bindingButton: bindingButton,
        resetButton: resetButton,
        copyFromVersionButton: copyButton,
      );
    }

    return PropFieldShell(
      label: field.label,
      isRequired: field.isRequired,
      helpText: field.helpText,
      actions: [?bindingButton, ?resetButton, ?copyButton],
      body: expression != null
          ? PropBindingEditor(
              expression: expression,
              onClear: () => onChanged(null),
            )
          : TypedPropEditor(
              field: field,
              value: value,
              onChanged: onChanged,
            ),
    );
  }
}
