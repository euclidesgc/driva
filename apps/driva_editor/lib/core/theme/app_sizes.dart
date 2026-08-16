import 'package:driva_editor/core/theme/app_spacing.dart';

/// Larguras de componente que não cabem no ritmo genérico de espaçamento —
/// medidas contra a composição real, não um valor de design abstrato.
abstract final class AppSizes {
  static const double categoryTreePanelWidth = 272;

  /// Largura fixa do campo de busca no cabeçalho do painel de conteúdos, em
  /// faixa larga (linha única, ao lado da ordenação e do modo de
  /// visualização).
  static const double contentPanelSearchWidth = 220;

  /// Abaixo desta largura de janela, o cabeçalho do painel de conteúdos
  /// (busca + ordenação + modo de visualização, numa linha ao lado da barra
  /// de categorias fixa) para de caber — soma [categoryTreePanelWidth] + 1
  /// (divisor) + 48 (padding do cabeçalho) + [contentPanelSearchWidth] + 10
  /// (vão) + 244 (ordenação + modo, medido). Não é breakpoint — é o limiar
  /// em que esta composição específica para de caber (mesmo papel de
  /// `topBarActionsFitWidth`, F3); não governa mais nada.
  static const double contentPanelWideHeaderFitWidth =
      categoryTreePanelWidth +
      1 +
      (AppSpacing.s24 * 2) +
      contentPanelSearchWidth +
      AppSpacing.s10 +
      244;

  /// Largura de conteúdo dos diálogos de formulário mais simples (conteúdo,
  /// categoria, mover conteúdo).
  static const double formDialogWidth = 380;

  /// Largura de conteúdo do diálogo de projeto — tem capa e descrição mais
  /// longa, por isso é mais largo que [formDialogWidth].
  static const double wideFormDialogWidth = 460;

  /// O orçamento horizontal que `DialogContentWidth` precisa descontar da
  /// tela: o `insetPadding` padrão do Material (`AlertDialog`) é 40px de
  /// cada lado — 80 no total. Só isso; o `contentPadding` interno do diálogo
  /// já está fora do que `DialogContentWidth` mede (ele embrulha o
  /// `content`, que já está dentro do `contentPadding`).
  static const double dialogInsetBudget = 80;

  /// Altura da barra de ferramentas do canvas (presets de device + zoom).
  static const double canvasToolbarHeight = 44;
}
