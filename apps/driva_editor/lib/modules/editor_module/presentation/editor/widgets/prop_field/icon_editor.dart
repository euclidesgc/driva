import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show iconLibraries;

/// Botão com a prévia do ícone atual (ou "None") que abre o [IconPickerDialog].
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
    final current = value is String && (value! as String).isNotEmpty
        ? value! as String
        : null;
    return OutlinedButton(
      onPressed: () async {
        final r = await showDialog<IconPickerResult>(
          context: context,
          builder: (_) => IconPickerDialog(
            selected: current,
            allowNone: !field.isRequired,
          ),
        );
        if (r != null) onChanged(r.value);
      },
      child: Row(
        children: [
          if (current != null) Icon(previewIconFor(current, iconLibraries)),
          if (current != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              current ?? 'None',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppTypography.base,
                color: current == null ? colors.inkMuted : colors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
