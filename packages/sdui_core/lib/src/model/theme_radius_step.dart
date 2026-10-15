enum ThemeRadiusStep {
  extraSmall,
  small,
  medium,
  large,
  extraLarge;

  static final Map<String, ThemeRadiusStep> _byName = values.asNameMap();

  static ThemeRadiusStep? fromName(String name) => _byName[name];
}
