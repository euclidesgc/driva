import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show curatedIconNames;

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/editor_colors.dart';

/// Fábrica `FieldKind → editor`: o Inspector deriva cada campo daqui.
/// Emitir `null` em [onChanged] remove a chave (volta ao default do renderer).
///
/// Os editores de texto guardam um [TextEditingController] próprio e a
/// identidade do campo vive na key do Inspector (`nodeId_fieldKey`), não no
/// valor — assim o campo não é recriado a cada tecla e o foco permanece.
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
      FieldKind.string => _StringEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.doubleNum => _NumberEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        isInt: false,
      ),
      FieldKind.intNum => _NumberEditor(
        field: field,
        value: value,
        onChanged: onChanged,
        isInt: true,
      ),
      FieldKind.boolean => _BoolEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.color => _ColorEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.enumeration => _EnumEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.edgeInsets => _EdgeInsetsEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.alignment => _AlignmentEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldKind.iconName => _IconEditor(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
    };

    final colors = Theme.of(context).extension<EditorColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: TextStyle(fontSize: 12, color: colors.inkSecondary),
              ),
              if (field.isRequired)
                const Text(' *', style: TextStyle(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          editor,
        ],
      ),
    );
  }
}

class _StringEditor extends StatefulWidget {
  const _StringEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_StringEditor> createState() => _StringEditorState();
}

class _StringEditorState extends State<_StringEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(covariant _StringEditor oldWidget) {
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
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(isDense: true),
      onChanged: (text) => widget.onChanged(
        text.isEmpty && !widget.field.isRequired ? null : text,
      ),
    );
  }
}

class _NumberEditor extends StatefulWidget {
  const _NumberEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.isInt,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool isInt;

  @override
  State<_NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<_NumberEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  num? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return widget.isInt
        ? int.tryParse(trimmed)
        : double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant _NumberEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ressincroniza só em mudança externa e quando o número realmente difere:
    // comparar por texto recolocaria o cursor no meio de "1." → "1.0".
    if (widget.value != oldWidget.value &&
        widget.value != _parse(_controller.text)) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(isDense: true, hintText: '—'),
      onChanged: (text) {
        if (text.trim().isEmpty) {
          widget.onChanged(null);
          return;
        }
        final parsed = _parse(text);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class _BoolEditor extends StatelessWidget {
  const _BoolEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value is bool
        ? value! as bool
        : (field.defaultValue as bool? ?? false);
    return Align(
      alignment: Alignment.centerLeft,
      child: Switch(value: current, onChanged: onChanged),
    );
  }
}

class _ColorEditor extends StatefulWidget {
  const _ColorEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
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
  void didUpdateWidget(covariant _ColorEditor oldWidget) {
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: current == null
                  ? Icon(
                      Icons.format_color_reset_outlined,
                      size: 14,
                      color: colors.inkMuted,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 13),
                inputFormatters: [_UpperCaseTextFormatter()],
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
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
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
                      borderRadius: BorderRadius.circular(4),
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

class _EnumEditor extends StatelessWidget {
  const _EnumEditor({
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
      style: TextStyle(fontSize: 13, color: colors.inkPrimary),
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

class _EdgeInsetsEditor extends StatefulWidget {
  const _EdgeInsetsEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_EdgeInsetsEditor> createState() => _EdgeInsetsEditorState();
}

class _EdgeInsetsEditorState extends State<_EdgeInsetsEditor> {
  static const _sides = ['left', 'top', 'right', 'bottom'];

  late final Map<String, TextEditingController> _controllers = {
    for (final side in _sides)
      side: TextEditingController(text: _side(side)?.toString() ?? ''),
  };

  double? _side(String key) {
    final map = widget.value;
    if (map is! Map) return null;
    if (map.containsKey('all')) return (map['all'] as num?)?.toDouble();
    return (map[key] as num?)?.toDouble();
  }

  double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant _EdgeInsetsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    for (final side in _sides) {
      final external = _side(side);
      if (external != _parse(_controllers[side]!.text)) {
        _controllers[side]!.text = external?.toString() ?? '';
      }
    }
  }

  void _update(String key, double? side) {
    final current = {for (final s in _sides) s: _side(s), key: side};
    if (current.values.every((v) => v == null)) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged({
      for (final entry in current.entries)
        if (entry.value != null) entry.key: entry.value,
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget sideField(String key, String label) => Expanded(
      child: TextField(
        controller: _controllers[key],
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10),
        ),
        onChanged: (text) => _update(key, _parse(text)),
      ),
    );

    return Row(
      children: [
        sideField('left', 'E'),
        const SizedBox(width: 4),
        sideField('top', 'T'),
        const SizedBox(width: 4),
        sideField('right', 'D'),
        const SizedBox(width: 4),
        sideField('bottom', 'B'),
      ],
    );
  }
}

class _AlignmentEditor extends StatelessWidget {
  const _AlignmentEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  static const _grid = [
    ['topLeft', 'topCenter', 'topRight'],
    ['centerLeft', 'center', 'centerRight'],
    ['bottomLeft', 'bottomCenter', 'bottomRight'],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rowValues in _grid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final alignment in rowValues)
                Tooltip(
                  message: alignment,
                  child: InkWell(
                    onTap: () =>
                        onChanged(value == alignment ? null : alignment),
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: value == alignment
                            ? colors.primaryTint
                            : colors.panel,
                        border: Border.all(
                          color: value == alignment
                              ? AppTheme.primary
                              : colors.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: value == alignment
                            ? AppTheme.primary
                            : colors.inkMuted,
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

class _IconEditor extends StatelessWidget {
  const _IconEditor({
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
    final names = curatedIconNames;
    final current = names.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      isDense: true,
      style: TextStyle(fontSize: 13, color: colors.inkPrimary),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          DropdownMenuItem<String?>(
            value: null,
            child: Text('—', style: TextStyle(color: colors.inkMuted)),
          ),
        for (final name in names)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
