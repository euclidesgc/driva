import 'package:equatable/equatable.dart';

class ThemeTextStyle extends Equatable {
  const ThemeTextStyle({
    required this.fontSize,
    required this.fontWeight,
    required this.lineHeight,
    required this.letterSpacing,
    this.fontFamily,
  });

  final double fontSize;

  /// Mesmo domínio da prop `fontWeight` do nó (`'w100'`…`'w900'`), para o
  /// estilo e a sobrescrita do nó compararem valores do mesmo tipo.
  final String fontWeight;

  /// Múltiplo do tamanho da fonte, como o `height` do `TextStyle`.
  final double lineHeight;

  final double letterSpacing;

  final String? fontFamily;

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'fontWeight': fontWeight,
    'lineHeight': lineHeight,
    'letterSpacing': letterSpacing,
    if (fontFamily != null) 'fontFamily': fontFamily,
  };

  @override
  List<Object?> get props => [
    fontSize,
    fontWeight,
    lineHeight,
    letterSpacing,
    fontFamily,
  ];
}
