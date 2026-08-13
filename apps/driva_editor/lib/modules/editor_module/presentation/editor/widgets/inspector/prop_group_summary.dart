import 'package:sdui_core/sdui_core.dart';

/// O resumo que a seção mostra quando está fechada — é ele que evita ter de
/// abrir cada seção para descobrir o que já foi mexido (padrão do FlutterFlow,
/// que mostra "None" ou o valor ao lado do título).
abstract final class PropGroupSummary {
  static const empty = '—';

  static String of(List<PropField> fields, Map<String, dynamic> properties) {
    final defined = [
      for (final field in fields)
        if (properties[field.key] != null) field,
    ];
    if (defined.isEmpty) return empty;
    if (defined.length == 1) {
      return describe(defined.first, properties[defined.first.key]);
    }
    return '${defined.length} definidas';
  }

  static String describe(PropField field, Object? value) {
    if (value == null) return empty;
    return switch (field.kind) {
      FieldKind.enumeration => _optionLabel(field, value),
      FieldKind.edgeInsets => _edgeInsets(value),
      FieldKind.boolean => (value == true) ? 'Sim' : 'Não',
      FieldKind.doubleNum || FieldKind.intNum => _number(value),
      FieldKind.dimension => _dimension(value),
      _ => value.toString(),
    };
  }

  static String _dimension(Object? value) => switch (DimensionValue.parse(
    value,
  )) {
    PixelDimension(:final pixels) => _number(pixels),
    PercentDimension() && final percent => percent.toJson().toString(),
    InfiniteDimension() => '∞',
    null => value.toString(),
  };

  static String _optionLabel(PropField field, Object? value) {
    for (final option in field.options) {
      if (option.value == value) return option.displayLabel;
    }
    return value.toString();
  }

  static String _number(Object? value) {
    if (value is! num) return value.toString();
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static String _edgeInsets(Object? value) {
    if (value is! Map) return value.toString();
    final all = value['all'];
    if (all != null) return _number(all);
    const sides = ['left', 'top', 'right', 'bottom'];
    return [
      for (final side in sides) _number(value[side] ?? 0),
    ].join(' · ');
  }
}
