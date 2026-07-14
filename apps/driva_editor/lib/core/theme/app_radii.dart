/// Escala de raios de canto do editor.
///
/// Invariante ao tema, por isso `static const` (consumidos direto, preservando
/// `const` nas `BorderRadius`). Calibrada pelos valores já usados no código.
/// `pill` é o raio "estádio" (cápsula) atual (`circular(999)`).
abstract final class AppRadii {
  static const double r3 = 3;
  static const double r4 = 4;
  static const double r6 = 6;
  static const double r7 = 7;
  static const double r8 = 8;
  static const double r9 = 9;
  static const double r11 = 11;
  static const double r12 = 12;
  static const double r13 = 13;
  static const double r14 = 14;
  static const double r15 = 15;
  static const double r16 = 16;
  static const double pill = 999;
}
