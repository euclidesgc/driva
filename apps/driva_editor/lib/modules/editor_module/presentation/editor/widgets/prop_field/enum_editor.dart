import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';

class EnumEditor extends StatelessWidget {
  const EnumEditor({
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
    final colors = Theme.of(context).extension<EditorColors>()!;
    final current = field.enumValues.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      isDense: true,
      style: TextStyle(fontSize: AppTypography.base, color: colors.inkPrimary),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          DropdownMenuItem<String?>(
            value: null,
            child: Text('—', style: TextStyle(color: colors.inkMuted)),
          ),
        for (final option in field.enumValues)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
    );
  }
}
