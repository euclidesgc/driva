import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/theme_color_list.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Resultado do popover: hex livre (`#AARRGGBB`) ou papel do tema.
sealed class ColorChoice {
  const ColorChoice();
}

final class FreeColorChoice extends ColorChoice {
  const FreeColorChoice(this.hex);
  final String hex;
}

final class ThemeColorChoice extends ColorChoice {
  const ThemeColorChoice(this.role);
  final ThemeColorRole role;
}

class ColorPickerPopover extends StatefulWidget {
  const ColorPickerPopover({
    required this.initial,
    this.selectedRole,
    super.key,
  });

  final Color initial;
  final String? selectedRole;

  @override
  State<ColorPickerPopover> createState() => _ColorPickerPopoverState();
}

class _ColorPickerPopoverState extends State<ColorPickerPopover> {
  late Color _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: SizedBox(
        width: AppSpacing.s420 * 1.6,
        height: AppSpacing.s420,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ColorPicker(
                  color: widget.initial,
                  onColorChanged: (c) => _picked = c,
                  enableOpacity: true,
                  showColorCode: true,
                  pickersEnabled: const {
                    ColorPickerType.primary: false,
                    ColorPickerType.accent: false,
                    ColorPickerType.wheel: true,
                    ColorPickerType.both: false,
                    ColorPickerType.bw: false,
                    ColorPickerType.custom: false,
                    ColorPickerType.customSecondary: false,
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: ThemeColorList(
                selected: widget.selectedRole,
                onSelected: (role) =>
                    Navigator.of(context).pop(ThemeColorChoice(role)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(
                context,
              ).pop(
                FreeColorChoice(
                  '#${_picked.a == 1 ? _picked.hex : _picked.hexAlpha}',
                ),
              ),
          child: const Text('Selecionar'),
        ),
      ],
    );
  }
}
