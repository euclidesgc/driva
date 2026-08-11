import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/prop_icons.dart';
import 'package:driva_editor/core/widgets/buttons/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Enum cujas options todas trazem `iconName` vira grupo de ícones — a forma
/// como o FlutterFlow edita alinhamento e afins. O tooltip carrega o label em
/// pt-BR, para o ícone não ser o único sinal de informação.
class EnumIconGroupEditor extends StatelessWidget {
  const EnumIconGroupEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        for (final option in field.options)
          ToggleButton(
            tooltip: option.displayLabel,
            icon: PropIcons.resolve(option.iconName)!,
            selected: value == option.value,
            onPressed: () => onChanged(
              value == option.value && !field.isRequired ? null : option.value,
            ),
          ),
      ],
    );
  }
}
