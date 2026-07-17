import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show curatedIconNames;

class IconEditor extends StatelessWidget {
  const IconEditor({
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
    final names = curatedIconNames;
    final current = names.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      style: TextStyle(fontSize: AppTypography.base, color: colors.inkPrimary),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          DropdownMenuItem<String?>(
            child: Text('—', style: TextStyle(color: colors.inkMuted)),
          ),
        for (final name in names)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: onChanged,
    );
  }
}
