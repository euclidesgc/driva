import 'package:sdui_core/src/model/alignment_value.dart';
import 'package:sdui_core/src/model/dimension_value.dart';

enum ComponentParamType {
  text('texto'),
  integer('número inteiro'),
  decimal('número decimal'),
  boolean('verdadeiro ou falso'),
  color('cor'),
  icon('ícone'),
  dimension('dimensão'),
  option('opção'),
  spacing('espaçamento'),
  alignment('alinhamento'),
  action('ação'),
  widgetBuilder('construtor de widget'),
  childWidget('widget filho');

  const ComponentParamType(this.label);

  final String label;

  static const spacingKeys = {
    'all',
    'horizontal',
    'vertical',
    'top',
    'left',
    'right',
    'bottom',
  };

  static final _hexColor = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

  bool get isData =>
      this != action && this != widgetBuilder && this != childWidget;

  static ComponentParamType? fromName(Object? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return null;
  }

  bool accepts(
    Object? value, {
    required bool isList,
    List<String> options = const [],
  }) {
    if (!isList) return _acceptsItem(value, options);
    return value is List && value.every((item) => _acceptsItem(item, options));
  }

  bool _acceptsItem(Object? value, List<String> options) => switch (this) {
    text || icon => value is String,
    integer => value is int,
    decimal => value is num,
    boolean => value is bool,
    color => value is String && _hexColor.hasMatch(value),
    dimension => DimensionValue.parse(value) != null,
    option => value is String && options.contains(value),
    spacing => _isSpacing(value),
    alignment => AlignmentValue.parse(value) != null,
    action => value is List && value.every(_isAction),
    widgetBuilder || childWidget => _isNodeShape(value),
  };

  static bool _isSpacing(Object? value) =>
      value is Map &&
      value.entries.every(
        (entry) => spacingKeys.contains(entry.key) && entry.value is num,
      );

  static bool _isAction(Object? value) =>
      value is Map && _isNonEmptyString(value['action']);

  static bool _isNodeShape(Object? value) =>
      value is Map &&
      _isNonEmptyString(value['id']) &&
      _isNonEmptyString(value['type']);

  static bool _isNonEmptyString(Object? value) =>
      value is String && value.isNotEmpty;
}
