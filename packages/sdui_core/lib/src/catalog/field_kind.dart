import 'package:sdui_core/src/catalog/prop_value_type.dart';

enum FieldKind {
  string(PropValueType.text),
  doubleNum(PropValueType.decimal),
  intNum(PropValueType.integer),

  /// Largura/altura: pixels, percentual do pai ou "preenche" — ver
  /// `DimensionValue`. Separado de [doubleNum] porque o domínio do valor é
  /// outro (`num | String`), e disso decorrem editor, resumo e parser próprios.
  dimension(PropValueType.dimension),
  boolean(PropValueType.boolean),
  color(PropValueType.color),
  enumeration(PropValueType.option),
  edgeInsets(PropValueType.spacing),
  alignment(PropValueType.alignment),
  iconName(PropValueType.icon);

  const FieldKind(this.valueType);

  final PropValueType valueType;
}
