enum ThemeColorRole {
  primary,
  secondary,
  tertiary,
  alternate,
  primaryText,
  secondaryText,
  primaryBackground,
  secondaryBackground,
  accent1,
  accent2,
  accent3,
  accent4,
  success,
  warning,
  error,
  info;

  static final Map<String, ThemeColorRole> _byName = values.asNameMap();

  static ThemeColorRole? fromName(String name) => _byName[name];
}
