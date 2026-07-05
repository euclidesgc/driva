import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/json_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = TextStyle(fontSize: 12);

  Color? colorOf(List<TextSpan> spans, String text) {
    for (final span in spans) {
      if (span.text == text) return span.style?.color;
    }
    return null;
  }

  test('preserva o texto exato (nada perdido nem duplicado)', () {
    const json = '{\n  "a": 1,\n  "b": "x"\n}';
    final spans = JsonHighlighter.highlight(json, base: base);
    final rebuilt = spans.map((s) => s.text).join();
    expect(rebuilt, json);
  });

  test('colore chave e string de valor com cores distintas', () {
    const json = '{"name": "driva"}';
    final spans = JsonHighlighter.highlight(json, base: base);
    expect(colorOf(spans, '"name"'), JsonHighlightColors.key);
    expect(colorOf(spans, '"driva"'), JsonHighlightColors.string);
  });

  test('colore números (inteiros e negativos)', () {
    const json = '{"n": 42, "m": -7}';
    final spans = JsonHighlighter.highlight(json, base: base);
    expect(colorOf(spans, '42'), JsonHighlightColors.number);
    expect(colorOf(spans, '-7'), JsonHighlightColors.number);
  });

  test('colore literais true/false/null', () {
    const json = '{"a": true, "b": false, "c": null}';
    final spans = JsonHighlighter.highlight(json, base: base);
    expect(colorOf(spans, 'true'), JsonHighlightColors.keyword);
    expect(colorOf(spans, 'false'), JsonHighlightColors.keyword);
    expect(colorOf(spans, 'null'), JsonHighlightColors.keyword);
  });

  test('string com aspas escapadas não quebra o span', () {
    const json = '{"q": "a \\"b\\" c"}';
    final spans = JsonHighlighter.highlight(json, base: base);
    expect(colorOf(spans, '"a \\"b\\" c"'), JsonHighlightColors.string);
  });

  test('pontuação recebe a cor de punctuation', () {
    const json = '[1,2]';
    final spans = JsonHighlighter.highlight(json, base: base);
    expect(colorOf(spans, '['), JsonHighlightColors.punctuation);
    expect(colorOf(spans, ']'), JsonHighlightColors.punctuation);
    expect(colorOf(spans, ','), JsonHighlightColors.punctuation);
  });
}
