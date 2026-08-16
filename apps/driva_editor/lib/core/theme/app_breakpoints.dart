/// Limiares de largura do chrome do editor (Material 3: compact < 600,
/// medium 600–1023, expanded >= 1024). Vocabulário de tema, não do kernel —
/// não importa o enum de faixa do spec SDUI: são dois vocabulários com os
/// mesmos números por coincidência de propósito, não por serem a mesma
/// coisa (D5).
abstract final class AppBreakpoints {
  static const double compact = 600;

  static const double medium = 1024;

  static bool isCompact(double width) => width < compact;
}
