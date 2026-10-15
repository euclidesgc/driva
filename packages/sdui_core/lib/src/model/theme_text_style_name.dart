enum ThemeTextStyleName {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall;

  static final Map<String, ThemeTextStyleName> _byName = values.asNameMap();

  static ThemeTextStyleName? fromName(String name) => _byName[name];
}
