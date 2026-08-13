enum FieldKind {
  string,
  doubleNum,
  intNum,

  /// Largura/altura: pixels, percentual do pai ou "preenche" — ver
  /// `DimensionValue`. Separado de [doubleNum] porque o domínio do valor é
  /// outro (`num | String`), e disso decorrem editor, resumo e parser próprios.
  dimension,
  boolean,
  color,
  enumeration,
  edgeInsets,
  alignment,
  iconName,
}
