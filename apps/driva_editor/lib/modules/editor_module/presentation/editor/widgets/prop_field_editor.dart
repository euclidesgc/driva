import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
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
    required this.onBind,
    required this.onUnbind,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Grava a ligação a uma variável (o cubit guarda o valor fixo por baixo).
  final ValueChanged<BoundPropValue> onBind;

  /// Remove a ligação e restaura o valor fixo que estava por baixo.
  final VoidCallback onUnbind;

  /// Kinds cujo editor monta a própria moldura: precisam de um controle na
  /// linha do rótulo que compartilha estado com o corpo (a unidade do campo de
  /// dimensão, o modo uniforme/lado a lado do espaçamento), e o wrapper não
  /// tem como entregar isso de fora.
  static const Set<FieldKind> _selfChromed = {
    FieldKind.dimension,
    FieldKind.edgeInsets,
  };

  BoundPropValue? get _binding => switch (parsePropValue(value)) {
    Right(value: final BoundPropValue bound) => bound,
    _ => null,
  };

  Future<void> _editBinding(BuildContext context) async {
    final current = _binding;
    final result = await showDialog<BoundPropValue>(
      context: context,
      builder: (_) => BindingDialog(
        field: field,
        bindingContext: BindingContext.page,
        initial: current,
        initialFallback: current == null ? value : null,
      ),
    );
    if (result == null) return;
    onBind(result);
  }

  @override
  Widget build(BuildContext context) {
    final binding = _binding;
    final isBound = binding != null;
    final bindingButton = field.isBindable
        ? PropBindingButton(
            isActive: isBound,
            onPressed: () => _editBinding(context),
          )
        : null;
    final resetButton = value != null && !field.isRequired && !isBound
        ? PropResetButton(onPressed: () => onChanged(null))
        : null;

    if (!isBound && _selfChromed.contains(field.kind)) {
      return SelfChromedPropEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        bindingButton: bindingButton,
        resetButton: resetButton,
      );
    }

    return PropFieldShell(
      label: field.label,
      isRequired: field.isRequired,
      helpText: field.helpText,
      actions: [?bindingButton, ?resetButton],
      body: binding != null
          ? BindingChip(
              binding: binding,
              onTap: () => _editBinding(context),
              onRemove: onUnbind,
            )
          : TypedPropEditor(field: field, value: value, onChanged: onChanged),
    );
  }
}
