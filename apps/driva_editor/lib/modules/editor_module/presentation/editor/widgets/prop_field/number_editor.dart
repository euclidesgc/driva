import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/number_text_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/numeric_clamp.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class NumberEditor extends StatefulWidget {
  const NumberEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.isInt,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool isInt;

  @override
  State<NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<NumberEditor> {
  static const _sliderWidth = 72.0;

  late final TextEditingController _controller = TextEditingController(
    text: _formatValue(widget.value),
  );

  String _formatValue(Object? value) =>
      value is num ? formatNumber(value) : value?.toString() ?? '';

  bool _hasError = false;
  String? _clampMessage;

  num? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return widget.isInt
        ? int.tryParse(trimmed)
        : tryParseFiniteDouble(trimmed.replaceAll(',', '.'));
  }

  /// Mesmo contrato do `DimensionEditor`: o valor emitido é clampado contra
  /// `field.min`/`field.max`, mas o texto digitado fica como está — reescrevê-lo
  /// a cada tecla moveria o cursor.
  num _clamp(num value) {
    final clamped = clampToRange(
      value,
      min: widget.field.min,
      max: widget.field.max,
    );
    return widget.isInt ? clamped.round() : clamped.toDouble();
  }

  num? _committedValueOf(String text) {
    final parsed = _parse(text);
    return parsed == null ? null : _clamp(parsed);
  }

  @override
  void didUpdateWidget(covariant NumberEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ressincroniza só em mudança externa; comparar por texto moveria o cursor.
    if (widget.value != oldWidget.value &&
        widget.value != _committedValueOf(_controller.text)) {
      _controller.text = _formatValue(widget.value);
      _hasError = false;
      _clampMessage = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSignal({required bool hasError, String? clampMessage}) {
    if (_hasError == hasError && _clampMessage == clampMessage) return;
    setState(() {
      _hasError = hasError;
      _clampMessage = clampMessage;
    });
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      _setSignal(hasError: false);
      widget.onChanged(null);
      return;
    }
    final parsed = _parse(text);
    if (parsed == null) {
      _setSignal(hasError: true);
      return;
    }
    final clamped = _clamp(parsed);
    _setSignal(
      hasError: false,
      clampMessage: clampMessageFor(parsed, clamped, min: widget.field.min),
    );
    widget.onChanged(clamped);
  }

  void _onSliderChanged(double raw) {
    final value = widget.isInt ? raw.round() : raw;
    _controller.text = formatNumber(value);
    _setSignal(hasError: false);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final numberField = NumberTextField(
      controller: _controller,
      onChanged: _onTextChanged,
      errorText: _hasError ? invalidNumberMessage : null,
      helperText: _clampMessage,
    );

    if (!field.hasRange) return numberField;

    final min = field.min!.toDouble();
    final max = field.max!.toDouble();
    final current =
        (_parse(_controller.text) ?? field.defaultValue as num? ?? min)
            .toDouble()
            .clamp(min, max);
    final step = field.step?.toDouble() ?? (widget.isInt ? 1.0 : null);

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: current,
            min: min,
            max: max,
            divisions: step == null ? null : ((max - min) / step).round(),
            label: widget.isInt
                ? current.round().toString()
                : current.toStringAsFixed(1),
            onChanged: _onSliderChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        SizedBox(width: _sliderWidth, child: numberField),
      ],
    );
  }
}
