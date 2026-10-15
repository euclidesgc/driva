import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/typed_prop_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Um valor do binding (o padrão ou a prévia) editado com o mesmo editor
/// tipado do campo, para que o valor tenha o tipo que a prop espera.
class BindingValueField extends StatelessWidget {
  const BindingValueField({
    required this.label,
    required this.field,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
    super.key,
  });

  final String label;
  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return PropFieldShell(
      label: label,
      isRequired: isRequired,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TypedPropEditor(field: field, value: value, onChanged: onChanged),
          if (errorText case final error?) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              error,
              style: TextStyle(
                fontSize: AppTypography.sm,
                color: colors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
