/// Limiares de largura que governam o comportamento por faixa das telas de
/// **navegação** (home de projetos, detalhe do projeto, categorias, lista de
/// conteúdos). Mesmos números do item 30 (Material 3), mas um vocabulário
/// próprio do editor: nunca importa o enum de faixa do `sdui_core` — chrome
/// da ferramenta e faixa do spec do cliente são coisas diferentes.
///
/// O `editor_module` consulta este arquivo em exatamente um lugar —
/// `editor_viewport_gate.dart` —, e é **substituição, não adaptação**: abaixo
/// de [compact] o construtor não é montado, e a UI dele nunca vê faixa
/// nenhuma (D5, D23).
abstract final class AppBreakpoints {
  static const double compact = 600;

  static bool isCompact(double width) => width < compact;
}
