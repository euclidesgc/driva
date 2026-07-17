import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/upper_case_text_formatter.dart';
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
    text: widget.value?.toString() ?? '',
  );

  Color? _parse(Object? v) {
    if (v is! String || !v.startsWith('#')) return null;
    var hex = v.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    final intVal = int.tryParse(hex, radix: 16);
    return intVal == null ? null : Color(intVal);
  }

  @override
  void didUpdateWidget(covariant ColorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final external = widget.value?.toString() ?? '';
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
    final colors = Theme.of(context).extension<EditorColors>()!;
    final current = _parse(widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: current ?? Colors.transparent,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadii.r4),
              ),
              child: current == null
                  ? Icon(
                      Icons.format_color_reset_outlined,
                      size: 14,
                      color: colors.inkMuted,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: AppTypography.base),
                inputFormatters: const [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '#RRGGBB',
                ),
                onChanged: (text) {
                  final trimmed = text.trim();
                  if (trimmed.isEmpty) {
                    widget.onChanged(null);
                  } else if (_parse(trimmed) != null) {
                    widget.onChanged(trimmed);
                  }
                },
              ),
            ),
            if (widget.value != null)
              IconButton(
                tooltip: 'Limpar cor',
                iconSize: 16,
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
              Tooltip(
                message: hex,
                child: InkWell(
                  onTap: () => widget.onChanged(hex),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _parse(hex),
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(AppRadii.r4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
