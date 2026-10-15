import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/util/upper_case_text_formatter.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/color_picker_popover.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/color_preview_swatch.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/color_quick_swatch.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/theme_color_list.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class ColorEditor extends StatefulWidget {
  const ColorEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<ColorEditor> {
  static const _swatches = [
    '#E8602C',
    '#2F6BFF',
    '#16A34A',
    '#F0A020',
    '#DC2626',
    '#111827',
    '#6B7280',
    '#FFFFFF',
  ];

  late final TextEditingController _controller = TextEditingController(
    text: _display,
  );

  static const _themeKey = r'$theme';

  String? get _role {
    final v = widget.value;
    return v is Map && v[_themeKey] is String ? v[_themeKey] as String : null;
  }

  String get _display => _role ?? widget.value?.toString() ?? '';

  Color? _parse(Object? v) {
    final role = v is Map && v[_themeKey] is String
        ? ThemeColorRole.fromName(v[_themeKey] as String)
        : null;
    if (role != null) return parseThemeHex(kDefaultProjectTheme.colors[role]);
    if (v is! String || !v.startsWith('#')) return null;
    var hex = v.substring(1);
    if (hex.length != 6 && hex.length != 8) return null;
    if (hex.length == 6) hex = 'FF$hex';
    final intVal = int.tryParse(hex, radix: 16);
    return intVal == null ? null : Color(intVal);
  }

  Future<void> _openFullPicker() async {
    final choice = await showDialog<ColorChoice>(
      context: context,
      builder: (_) => ColorPickerPopover(
        initial: _parse(widget.value) ?? Colors.white,
        selectedRole: _role,
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case FreeColorChoice(:final hex):
        _controller.text = hex;
        widget.onChanged(hex);
      case ThemeColorChoice(:final role):
        _controller.text = role.name;
        widget.onChanged({_themeKey: role.name});
    }
  }

  @override
  void didUpdateWidget(covariant ColorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final external = _display;
    if (widget.value != oldWidget.value && external != _controller.text) {
      _controller.text = external;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _parse(widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColorPreviewSwatch(color: current, onTap: _openFullPicker),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: AppTypography.base),
                inputFormatters: const [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '#AARRGGBB',
                ),
                onChanged: (text) {
                  final trimmed = text.trim();
                  if (trimmed.isEmpty) {
                    widget.onChanged(null);
                  } else if (trimmed.startsWith('#') &&
                      _parse(trimmed) != null) {
                    widget.onChanged(trimmed);
                  }
                },
              ),
            ),
            if (widget.value != null)
              IconButton(
                tooltip: 'Limpar cor',
                iconSize: AppIconSizes.s16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () => widget.onChanged(null),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        Wrap(
          spacing: AppSpacing.s6,
          children: [
            for (final hex in _swatches)
              ColorQuickSwatch(
                hex: hex,
                color: _parse(hex)!,
                onTap: () => widget.onChanged(hex),
              ),
          ],
        ),
      ],
    );
  }
}
