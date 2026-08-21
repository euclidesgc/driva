import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/dimension_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Despacho dos kinds que montam a própria `PropFieldShell`. Espelha o
/// `TypedPropEditor`, mas para os editores que precisam pendurar um controle na
/// linha do rótulo.
///
/// Os botões de canto chegam separados porque o editor decide se cada um cabe:
/// dimensão em porcentagem, por exemplo, não aceita binding.
class SelfChromedPropEditor extends StatelessWidget {
  const SelfChromedPropEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    this.bindingButton,
    this.resetButton,
    this.copyFromVersionButton,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final Widget? bindingButton;
  final Widget? resetButton;
  final Widget? copyFromVersionButton;

  @override
  Widget build(BuildContext context) => switch (field.kind) {
    FieldKind.dimension => DimensionEditor(
      field: field,
      value: value,
      onChanged: onChanged,
      bindingButton: bindingButton,
      resetButton: resetButton,
      copyFromVersionButton: copyFromVersionButton,
    ),
    _ => const SizedBox.shrink(),
  };
}
