import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/dimension_unit_toggle.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/number_text_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/numeric_clamp.dart';
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

  bool _hasError = false;
  String? _clampMessage;

  static DimensionUnit _unitOf(Object? value) =>
      DimensionValue.parse(value) is PercentDimension
      ? DimensionUnit.percent
      : DimensionUnit.pixels;

  static String _textOf(Object? value) => switch (DimensionValue.parse(value)) {
    PixelDimension(:final pixels) => formatNumber(pixels),
    PercentDimension(:final fraction) => formatNumber(fraction * 100),
    InfiniteDimension() => DimensionValue.infiniteToken,
    null => '',
  };

  bool get _isInfinite =>
      DimensionValue.parse(widget.value) is InfiniteDimension;

  // `field.min`/`max` são sempre em pixels — o teto não faz sentido em
  // percentual (150% de largura é transbordo intencional), mas o piso 0 vale
  // nos dois: um valor negativo não é uma dimensão em nenhuma unidade.
  Object? _encode(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == DimensionValue.infiniteToken) {
      return _unit == DimensionUnit.pixels
          ? DimensionValue.infiniteToken
          : null;
    }

    final number = _parseNumber(trimmed);
    if (number == null) return null;

    if (_unit == DimensionUnit.percent) {
      return PercentDimension(_clampedPercent(number) / 100).toJson();
    }
    return _clampedPixels(number);
  }

  num _clampedPercent(num raw) => clampToRange(raw, min: 0);

  double _clampedPixels(num raw) => clampToRange(
    raw,
    min: widget.field.min ?? 0,
    max: widget.field.max,
  ).toDouble();

  static double? _parseNumber(String trimmed) =>
      tryParseFiniteDouble(trimmed.replaceAll(',', '.'));

  void _setSignal({required bool hasError, String? clampMessage}) {
    if (_hasError == hasError && _clampMessage == clampMessage) return;
    setState(() {
      _hasError = hasError;
      _clampMessage = clampMessage;
    });
  }

  void _onTextChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _setSignal(hasError: false);
      widget.onChanged(null);
      return;
    }

    if (trimmed == DimensionValue.infiniteToken) {
      final isValid = _unit == DimensionUnit.pixels;
      _setSignal(hasError: !isValid);
      if (isValid) widget.onChanged(DimensionValue.infiniteToken);
      return;
    }

    final number = _parseNumber(trimmed);
    if (number == null) {
      _setSignal(hasError: true);
      return;
    }

    if (_unit == DimensionUnit.percent) {
      final clamped = _clampedPercent(number);
      _setSignal(
        hasError: false,
        clampMessage: clampMessageFor(number, clamped, min: 0),
      );
      widget.onChanged(PercentDimension(clamped / 100).toJson());
      return;
    }

    final clamped = _clampedPixels(number);
    _setSignal(
      hasError: false,
      clampMessage: clampMessageFor(
        number,
        clamped,
        min: widget.field.min ?? 0,
      ),
    );
    widget.onChanged(clamped);
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
      _hasError = false;
      _clampMessage = null;
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
      _hasError = false;
      _clampMessage = null;
    });
    widget.onChanged(null);
  }

  void _fillAvailable() {
    _controller.text = DimensionValue.infiniteToken;
    _setSignal(hasError: false);
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
      body: NumberTextField(
        controller: _controller,
        onChanged: _onTextChanged,
        errorText: _hasError ? invalidNumberMessage : null,
        helperText: _clampMessage,
        hintText: acceptsInfinite ? 'auto' : '0+',
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
      ),
    );
  }
}
