import 'package:driva_editor/core/theme/syntax_colors.dart';
import 'package:driva_editor/core/widgets/painters/painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = TextStyle(fontSize: 12);
  const colors = SyntaxColors.light;

  Color? colorOf(List<TextSpan> spans, String text) {
    for (final span in spans) {
      if (span.text == text) return span.style?.color;
    }
    return null;
  }

  test('preserva o texto exato (nada perdido nem duplicado)', () {
    const json = '{\n  "a": 1,\n  "b": "x"\n}';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    final rebuilt = spans.map((s) => s.text).join();
    expect(rebuilt, json);
  });

  test('colore chave e string de valor com cores distintas', () {
    const json = '{"name": "driva"}';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    expect(colorOf(spans, '"name"'), SyntaxColors.light.key);
    expect(colorOf(spans, '"driva"'), SyntaxColors.light.string);
  });

  test('colore números (inteiros e negativos)', () {
    const json = '{"n": 42, "m": -7}';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    expect(colorOf(spans, '42'), SyntaxColors.light.number);
    expect(colorOf(spans, '-7'), SyntaxColors.light.number);
  });

  test('colore literais true/false/null', () {
    const json = '{"a": true, "b": false, "c": null}';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    expect(colorOf(spans, 'true'), SyntaxColors.light.keyword);
    expect(colorOf(spans, 'false'), SyntaxColors.light.keyword);
    expect(colorOf(spans, 'null'), SyntaxColors.light.keyword);
  });

  test('string com aspas escapadas não quebra o span', () {
    const json = '{"q": "a \\"b\\" c"}';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    expect(colorOf(spans, '"a \\"b\\" c"'), SyntaxColors.light.string);
  });

  test('pontuação recebe a cor de punctuation', () {
    const json = '[1,2]';
    final spans = JsonHighlighter.highlight(json, base: base, colors: colors);
    expect(colorOf(spans, '['), SyntaxColors.light.punctuation);
    expect(colorOf(spans, ']'), SyntaxColors.light.punctuation);
    expect(colorOf(spans, ','), SyntaxColors.light.punctuation);
  });
}
