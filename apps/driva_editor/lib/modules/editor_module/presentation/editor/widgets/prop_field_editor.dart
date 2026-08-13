import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/theme/prop_icons.dart';
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

  /// Enum só vira grupo de ícones quando **toda** option resolve um ícone —
  /// meia paleta de ícones e meia de rótulos seria pior que o dropdown.
  bool get _rendersAsIconGroup =>
      field.kind == FieldKind.enumeration &&
      field.options.isNotEmpty &&
      field.options.every((option) => PropIcons.has(option.iconName));

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
      FieldKind.enumeration when _rendersAsIconGroup => EnumIconGroupEditor(
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
              const Spacer(),
              if (value != null && !field.isRequired)
                PropResetButton(onPressed: () => onChanged(null)),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          editor,
        ],
      ),
    );
  }
}
