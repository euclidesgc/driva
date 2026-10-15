import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_mode_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_side_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/number_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/numeric_clamp.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field_shell.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Dois modos, como no FlutterFlow: **uniforme** grava `{all: X}` com slider e
/// campo; **por lado** grava os lados presentes e mostra os quatro. O modo
/// inicial vem do valor; trocar de modo só muda a tela, não o nó.
class EdgeInsetsEditor extends StatefulWidget {
  const EdgeInsetsEditor({
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
  State<EdgeInsetsEditor> createState() => _EdgeInsetsEditorState();
}

class _EdgeInsetsEditorState extends State<EdgeInsetsEditor> {
  static const _sides = ['left', 'top', 'right', 'bottom'];
  static const _sideLabels = {
    'left': 'E',
    'top': 'T',
    'right': 'D',
    'bottom': 'B',
  };

  late EdgeInsetsMode _mode = EdgeInsetsValue.modeOf(widget.value);

  late final Map<String, TextEditingController> _controllers = {
    for (final side in _sides)
      side: TextEditingController(
        text: _format(EdgeInsetsValue.sideOf(widget.value, side)),
      ),
  };

  String? _clampMessage;

  String _format(double? value) => value == null ? '' : formatNumber(value);

  double _clamp(double value) => clampToRange(
    value,
    min: widget.field.min,
    max: widget.field.max,
  ).toDouble();

  double? _committedSideOf(String text) {
    final parsed = _parse(text);
    return parsed == null ? null : _clamp(parsed);
  }

  bool _sidesDiffer(Object? a, Object? b) => _sides.any(
    (side) =>
        EdgeInsetsValue.sideOf(a, side) != EdgeInsetsValue.sideOf(b, side),
  );

  double? _parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  void didUpdateWidget(covariant EdgeInsetsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    var hasExternalChange = false;
    for (final side in _sides) {
      final external = EdgeInsetsValue.sideOf(widget.value, side);
      if (external != _committedSideOf(_controllers[side]!.text)) {
        _controllers[side]!.text = _format(external);
        hasExternalChange = true;
      }
    }
    if (hasExternalChange) _clampMessage = null;
    if (_mode == EdgeInsetsMode.uniform &&
        _sidesDiffer(widget.value, oldWidget.value) &&
        EdgeInsetsValue.modeOf(widget.value) == EdgeInsetsMode.perSide) {
      _mode = EdgeInsetsMode.perSide;
    }
  }

  void _onSideTextChanged(String side, String text) {
    final parsed = _parse(text);
    final clamped = parsed == null ? null : _clamp(parsed);
    final message = parsed == null || clamped == null
        ? null
        : clampMessageFor(parsed, clamped, min: widget.field.min);
    if (message != _clampMessage) setState(() => _clampMessage = message);
    _updateSide(side, clamped);
  }

  void _updateSide(String key, double? side) {
    final current = {
      for (final s in _sides) s: EdgeInsetsValue.sideOf(widget.value, s),
      key: side,
    };
    if (current.values.every((v) => v == null)) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged({
      for (final entry in current.entries)
        if (entry.value != null) entry.key: entry.value,
    });
  }

  void _updateUniform(double? all) {
    widget.onChanged(all == null ? null : {'all': all});
  }

  void _changeMode(EdgeInsetsMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
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
    return PropFieldShell(
      label: widget.field.label,
      isRequired: widget.field.isRequired,
      helpText: widget.field.helpText,
      headerTrailing: EdgeInsetsModeBar(
        isUniform: _mode == EdgeInsetsMode.uniform,
        onChanged: (isUniform) => _changeMode(
          isUniform ? EdgeInsetsMode.uniform : EdgeInsetsMode.perSide,
        ),
      ),
      actions: [?widget.bindingButton, ?widget.resetButton],
      body: _mode == EdgeInsetsMode.uniform
          ? NumberEditor(
              field: widget.field,
              value: EdgeInsetsValue.uniformOf(widget.value),
              onChanged: (v) => _updateUniform(v is num ? v.toDouble() : null),
              isInt: false,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final side in _sides) ...[
                      if (side != _sides.first)
                        const SizedBox(width: AppSpacing.s4),
                      EdgeInsetsSideField(
                        controller: _controllers[side],
                        label: _sideLabels[side]!,
                        onChanged: (text) => _onSideTextChanged(side, text),
                      ),
                    ],
                  ],
                ),
                if (_clampMessage case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s4),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: AppTypography.xs,
                        color: Theme.of(
                          context,
                        ).extension<EditorColors>()!.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
