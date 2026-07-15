import 'package:flutter/material.dart';

/// Paleta do syntax highlight do JSON (chave, string, número, literal,
/// pontuação, texto neutro).
///
/// Registrada como [ThemeExtension] com slots claro/escuro: é o caso que mais
/// se beneficia de uma variante escura real (cores calibradas para painel
/// claro perdem contraste no escuro). Hoje os dois slots são **idênticos** aos
/// valores atuais (que o `json_highlighter.dart` usava fixos, independente do
/// tema), então tokenizar não muda nada agora; diferenciar o escuro depois é
/// mexer só neste arquivo.
///
/// Acessibilidade: a cor não é o único sinal — o JSON continua legível
/// indentado; o realce só reforça a estrutura já visível.
class SyntaxColors extends ThemeExtension<SyntaxColors> {
  const SyntaxColors({
    required this.key,
    required this.string,
    required this.number,
    required this.keyword,
    required this.punctuation,
    required this.plain,
  });

  /// Chave de objeto (string seguida de `:`).
  final Color key;

  /// Valor string.
  final Color string;

  /// Número.
  final Color number;

  /// Literal (`true`/`false`/`null`).
  final Color keyword;

  /// Pontuação estrutural (`{}`, `[]`, `:`, `,`).
  final Color punctuation;

  /// Texto neutro (fallback).
  final Color plain;

  static const SyntaxColors light = SyntaxColors(
    key: Color(0xFF0550AE),
    string: Color(0xFF0A7C42),
    number: Color(0xFFB45309),
    keyword: Color(0xFF8250DF),
    punctuation: Color(0xFF6B7280),
    plain: Color(0xFF3A3F47),
  );

  /// Idêntico ao claro por ora (o highlighter usava as mesmas cores nos dois
  /// temas). Diferenciar o escuro é uma mudança futura só aqui.
  static const SyntaxColors dark = light;

  @override
  SyntaxColors copyWith({
    Color? key,
    Color? string,
    Color? number,
    Color? keyword,
    Color? punctuation,
    Color? plain,
  }) {
    return SyntaxColors(
      key: key ?? this.key,
      string: string ?? this.string,
      number: number ?? this.number,
      keyword: keyword ?? this.keyword,
      punctuation: punctuation ?? this.punctuation,
      plain: plain ?? this.plain,
    );
  }

  @override
  SyntaxColors lerp(covariant SyntaxColors? other, double t) {
    if (other == null) return this;
    return SyntaxColors(
      key: Color.lerp(key, other.key, t)!,
      string: Color.lerp(string, other.string, t)!,
      number: Color.lerp(number, other.number, t)!,
      keyword: Color.lerp(keyword, other.keyword, t)!,
      punctuation: Color.lerp(punctuation, other.punctuation, t)!,
      plain: Color.lerp(plain, other.plain, t)!,
    );
  }
}
