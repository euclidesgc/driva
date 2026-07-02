import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart' show curatedIconNames;

import '../../../../../core/theme/app_theme.dart';

/// Fábrica `FieldKind → editor`: o Inspector deriva cada campo daqui.
/// Emitir `null` em [onChanged] remove a chave (volta ao default do renderer).
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
      FieldKind.string => _StringEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.doubleNum => _NumberEditor(field: field, value: value, onChanged: onChanged, isInt: false),
      FieldKind.intNum => _NumberEditor(field: field, value: value, onChanged: onChanged, isInt: true),
      FieldKind.boolean => _BoolEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.color => _ColorEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.enumeration => _EnumEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.edgeInsets => _EdgeInsetsEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.alignment => _AlignmentEditor(field: field, value: value, onChanged: onChanged),
      FieldKind.iconName => _IconEditor(field: field, value: value, onChanged: onChanged),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.inkSecondary,
                ),
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

class _StringEditor extends StatelessWidget {
  const _StringEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // A key troca o controller interno quando o nó/campo muda.
      key: ValueKey('${field.key}_${value ?? ''}_focusless'),
      initialValue: value?.toString() ?? '',
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(isDense: true),
      onChanged: (text) =>
          onChanged(text.isEmpty && !field.isRequired ? null : text),
    );
  }
}

class _NumberEditor extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('${field.key}_${value ?? ''}'),
      initialValue: value?.toString() ?? '',
      style: const TextStyle(fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(isDense: true, hintText: '—'),
      onChanged: (text) {
        if (text.trim().isEmpty) {
          onChanged(null);
          return;
        }
        final parsed = isInt
            ? int.tryParse(text.trim())
            : double.tryParse(text.trim().replaceAll(',', '.'));
        if (parsed != null) onChanged(parsed);
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
      child: Switch(
        value: current,
        onChanged: onChanged,
      ),
    );
  }
}

class _ColorEditor extends StatelessWidget {
  const _ColorEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  static const _swatches = [
    '#E8602C', '#2F6BFF', '#16A34A', '#F0A020', '#DC2626',
    '#111827', '#6B7280', '#FFFFFF',
  ];

  Color? _parse(Object? v) {
    if (v is! String || !v.startsWith('#')) return null;
    var hex = v.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    final intVal = int.tryParse(hex, radix: 16);
    return intVal == null ? null : Color(intVal);
  }

  @override
  Widget build(BuildContext context) {
    final current = _parse(value);
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
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: current == null
                  ? const Icon(Icons.format_color_reset_outlined,
                      size: 14, color: AppTheme.inkMuted)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('${field.key}_${value ?? ''}'),
                initialValue: value?.toString() ?? '',
                style: const TextStyle(fontSize: 13),
                decoration:
                    const InputDecoration(isDense: true, hintText: '#RRGGBB'),
                onChanged: (text) {
                  final trimmed = text.trim().toUpperCase();
                  if (trimmed.isEmpty) {
                    onChanged(null);
                  } else if (_parse(trimmed) != null) {
                    onChanged(trimmed);
                  }
                },
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Limpar cor',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () => onChanged(null),
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
                  onTap: () => onChanged(hex),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _parse(hex),
                      border: Border.all(color: AppTheme.border),
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
    final current =
        field.enumValues.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      isDense: true,
      style: const TextStyle(fontSize: 13, color: AppTheme.ink),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('—', style: TextStyle(color: AppTheme.inkMuted)),
          ),
        for (final option in field.enumValues)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
    );
  }
}

class _EdgeInsetsEditor extends StatelessWidget {
  const _EdgeInsetsEditor({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  double? _side(String key) {
    final map = value;
    if (map is! Map) return null;
    if (map.containsKey('all')) return (map['all'] as num?)?.toDouble();
    return (map[key] as num?)?.toDouble();
  }

  void _update(String key, double? side) {
    final current = {
      'left': _side('left'),
      'top': _side('top'),
      'right': _side('right'),
      'bottom': _side('bottom'),
      key: side,
    };
    if (current.values.every((v) => v == null)) {
      onChanged(null);
      return;
    }
    onChanged({
      for (final entry in current.entries)
        if (entry.value != null) entry.key: entry.value,
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget sideField(String key, String label) => Expanded(
          child: TextFormField(
            key: ValueKey('${field.key}_${key}_${_side(key) ?? ''}'),
            initialValue: _side(key)?.toString() ?? '',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              labelText: label,
              labelStyle: const TextStyle(fontSize: 10),
            ),
            onChanged: (text) => _update(
              key,
              text.trim().isEmpty
                  ? null
                  : double.tryParse(text.trim().replaceAll(',', '.')),
            ),
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
                            ? AppTheme.primaryTint
                            : AppTheme.surface,
                        border: Border.all(
                          color: value == alignment
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: value == alignment
                            ? AppTheme.primary
                            : AppTheme.inkMuted,
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
    final names = curatedIconNames;
    final current = names.contains(value) ? value! as String : null;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      isDense: true,
      style: const TextStyle(fontSize: 13, color: AppTheme.ink),
      decoration: const InputDecoration(isDense: true),
      items: [
        if (!field.isRequired)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('—', style: TextStyle(color: AppTheme.inkMuted)),
          ),
        for (final name in names)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: onChanged,
    );
  }
}
