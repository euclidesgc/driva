import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/editor_colors.dart';
import 'prop_field/prop_field.dart';

/// `null` em [onChanged] remove a chave (volta ao default do renderer).
///
/// A key do campo vem do Inspector (`nodeId_fieldKey`), nunca do valor: pelo
/// valor, o campo é recriado a cada tecla e o foco se perde.
class PropFieldEditor extends StatelessWidget {
  const PropFieldEditor({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final editor = switch (field.kind) {
      FieldKind.string => StringEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.doubleNum => NumberEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        isInt: false,
      ),
      FieldKind.intNum => NumberEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        isInt: true,
      ),
      FieldKind.boolean => BoolEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.color => ColorEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.enumeration => EnumEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.edgeInsets => EdgeInsetsEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.alignment => AlignmentEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.iconName => IconEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
    };

    final colors = Theme.of(context).extension<EditorColors>()!;
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
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          editor,
        ],
      ),
    );
  }
}
