import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/dimension_unit_toggle.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field_shell.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Largura/altura no padrão do FlutterFlow: unidade na linha do rótulo e, em
/// pixels, um `∞` dentro do campo para "preenche o disponível".
///
/// Percentual não oferece `∞` porque a combinação não quer dizer nada.
class DimensionEditor extends StatefulWidget {
  const DimensionEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    this.bindingButton,
    this.resetButton,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final Widget? bindingButton;
  final Widget? resetButton;

  @override
  State<DimensionEditor> createState() => _DimensionEditorState();
}

class _DimensionEditorState extends State<DimensionEditor> {
  late DimensionUnit _unit = _unitOf(widget.value);

  late final TextEditingController _controller = TextEditingController(
    text: _textOf(widget.value),
  );

  static DimensionUnit _unitOf(Object? value) =>
      DimensionValue.parse(value) is PercentDimension
      ? DimensionUnit.percent
      : DimensionUnit.pixels;

  static String _textOf(Object? value) => switch (DimensionValue.parse(value)) {
    PixelDimension(:final pixels) => _trimZero(pixels),
    PercentDimension(:final fraction) => _trimZero(fraction * 100),
    InfiniteDimension() => DimensionValue.infiniteToken,
    null => '',
  };

  static String _trimZero(double value) {
    final rounded = value.roundToDouble();
    return value == rounded
        ? rounded.toInt().toString()
        : value.toStringAsFixed(2);
  }

  bool get _isInfinite =>
      DimensionValue.parse(widget.value) is InfiniteDimension;

  Object? _encode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == DimensionValue.infiniteToken) {
      return _unit == DimensionUnit.pixels
          ? DimensionValue.infiniteToken
          : null;
    }

    final number = double.tryParse(trimmed.replaceAll(',', '.'));
    if (number == null) return null;

    final min = widget.field.min?.toDouble() ?? 0;
    final clamped = number < min ? min : number;
    return _unit == DimensionUnit.pixels
        ? clamped
        : PercentDimension(clamped / 100).toJson();
  }

  @override
  void didUpdateWidget(covariant DimensionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    // Comparar pelo valor, não pelo texto: comparar texto moveria o cursor a
    // cada tecla.
    if (_encode(_controller.text) != widget.value) {
      _controller.text = _textOf(widget.value);
      _unit = _unitOf(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeUnit(DimensionUnit unit) {
    if (unit == _unit) return;
    setState(() {
      _unit = unit;
      _controller.clear();
    });
    widget.onChanged(null);
  }

  void _fillAvailable() {
    _controller.text = DimensionValue.infiniteToken;
    widget.onChanged(DimensionValue.infiniteToken);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final acceptsInfinite = _unit == DimensionUnit.pixels;

    return PropFieldShell(
      label: widget.field.label,
      isRequired: widget.field.isRequired,
      helpText: widget.field.helpText,
      headerTrailing: DimensionUnitToggle(
        unit: _unit,
        onChanged: _changeUnit,
      ),
      // Binding só faz sentido em pixels: uma variável que devolve "70%" não
      // tem como ser validada aqui, e o FlutterFlow esconde o botão do mesmo
      // jeito.
      actions: [
        if (acceptsInfinite) ?widget.bindingButton,
        ?widget.resetButton,
      ],
      body: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: AppTypography.base),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          hintText: _unit == DimensionUnit.pixels ? 'auto' : '0–100',
          suffixIcon: acceptsInfinite
              ? IconButton(
                  tooltip: 'Preencher o espaço disponível',
                  iconSize: 14,
                  visualDensity: VisualDensity.compact,
                  color: _isInfinite ? colors.inkPrimary : colors.inkMuted,
                  icon: const Icon(Icons.all_inclusive),
                  onPressed: _fillAvailable,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
        onChanged: (text) => widget.onChanged(_encode(text)),
      ),
    );
  }
}
