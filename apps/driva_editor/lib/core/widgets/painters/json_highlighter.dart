import 'package:driva_editor/core/theme/syntax_colors.dart';
import 'package:flutter/material.dart';

/// Highlighter próprio (sem dependência) que colore um JSON já formatado
/// (indentado) em [TextSpan]s: chaves, strings, números, literais
/// (`true`/`false`/`null`) e pontuação.
///
/// Distingue chave de string de valor pelo caractere não-branco seguinte:
/// se for `:`, a string é uma chave. Trabalha sobre a saída de
/// `JsonEncoder.withIndent`, então não precisa ser um parser completo.
abstract final class JsonHighlighter {
  static List<TextSpan> highlight(
    String json, {
    required TextStyle base,
    required SyntaxColors colors,
  }) {
    final spans = <TextSpan>[];
    final length = json.length;
    var i = 0;

    TextStyle styled(Color color) => base.copyWith(color: color);

    while (i < length) {
      final char = json[i];

      if (char == '"') {
        final start = i;
        i++;
        while (i < length) {
          if (json[i] == r'\') {
            i += 2;
            continue;
          }
          if (json[i] == '"') {
            i++;
            break;
          }
          i++;
        }
        final text = json.substring(start, i);
        final isKey = _nextNonSpaceIsColon(json, i);
        spans.add(
          TextSpan(
            text: text,
            style: styled(isKey ? colors.key : colors.string),
          ),
        );
        continue;
      }

      if (char == '-' || (char.codeUnitAt(0) ^ 0x30) <= 9) {
        final start = i;
        while (i < length && _isNumberChar(json[i])) {
          i++;
        }
        spans.add(
          TextSpan(
            text: json.substring(start, i),
            style: styled(colors.number),
          ),
        );
        continue;
      }

      if (_startsWith(json, i, 'true') ||
          _startsWith(json, i, 'false') ||
          _startsWith(json, i, 'null')) {
        final keyword = json[i] == 'f'
            ? 'false'
            : json[i] == 't'
            ? 'true'
            : 'null';
        spans.add(TextSpan(text: keyword, style: styled(colors.keyword)));
        i += keyword.length;
        continue;
      }

      if (_isPunctuation(char)) {
        spans.add(TextSpan(text: char, style: styled(colors.punctuation)));
        i++;
        continue;
      }

      spans.add(TextSpan(text: char, style: styled(colors.plain)));
      i++;
    }

    return spans;
  }

  static bool _nextNonSpaceIsColon(String source, int from) {
    for (var j = from; j < source.length; j++) {
      final c = source[j];
      if (c == ' ' || c == '\n' || c == '\t' || c == '\r') continue;
      return c == ':';
    }
    return false;
  }

  static bool _isNumberChar(String c) {
    if ((c.codeUnitAt(0) ^ 0x30) <= 9) return true;
    return c == '.' || c == '-' || c == '+' || c == 'e' || c == 'E';
  }

  static bool _isPunctuation(String c) =>
      c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',';

  static bool _startsWith(String source, int from, String needle) {
    if (from + needle.length > source.length) return false;
    return source.substring(from, from + needle.length) == needle;
  }
}
