enum PropValueType {
  text,
  integer,
  decimal,
  dimension,
  boolean,
  color,
  option,
  spacing,
  alignment,
  icon,
  any,
  declared;

  bool feeds(PropValueType expected) =>
      this == expected ||
      this == any ||
      this == declared ||
      (this == integer && expected == decimal);
}
