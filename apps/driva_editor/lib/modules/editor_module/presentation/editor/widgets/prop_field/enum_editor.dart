import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class EnumEditor extends StatelessWidget {
  const EnumEditor({
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
    final colors = Theme.of(context).extension<EditorColors>()!;
    final current = field.enumValues.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      style: TextStyle(fontSize: AppTypography.base, color: colors.inkPrimary),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          DropdownMenuItem<String?>(
            child: Text('—', style: TextStyle(color: colors.inkMuted)),
          ),
        for (final option in field.enumValues)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
    );
  }
}
