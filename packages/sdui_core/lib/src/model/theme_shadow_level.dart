enum ThemeShadowLevel {
  level1,
  level2,
  level3,
  level4,
  level5;

  static final Map<String, ThemeShadowLevel> _byName = values.asNameMap();

  static ThemeShadowLevel? fromName(String name) => _byName[name];
}
