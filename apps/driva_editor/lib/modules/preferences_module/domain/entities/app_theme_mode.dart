/// Preferência de tema escolhida pelo usuário, persistida localmente.
///
/// Espelha o `ThemeMode` do Flutter, mas vive no domínio (Dart puro) para não
/// vazar `package:flutter` para contratos e use cases.
enum AppThemeMode {
  /// Segue o tema do sistema operacional.
  system,

  /// Tema claro, fixo.
  light,

  /// Tema escuro, fixo.
  dark,
}
