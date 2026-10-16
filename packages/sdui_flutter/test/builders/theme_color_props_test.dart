import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const _accent = Color(0xFF123456);

final _theme = ProjectTheme(
  colors: {...kDefaultProjectTheme.colors, ThemeColorRole.accent1: '#123456'},
  textStyles: kDefaultProjectTheme.textStyles,
  radii: kDefaultProjectTheme.radii,
  shadows: kDefaultProjectTheme.shadows,
);

const _themed = {r'$theme': 'accent1'};

Iterable<T> _all<T extends Widget>(WidgetTester tester) =>
    tester.widgetList<T>(find.byWidgetPredicate((w) => w is T));

ButtonStyle _buttonStyle(WidgetTester tester) =>
    _all<ButtonStyleButton>(tester).single.style!;

final Map<
  (String, String),
  (Map<String, dynamic>, Iterable<Color?> Function(WidgetTester))
>
_cases = {
  ('container', 'color'): ({}, (t) => _all<Container>(t).map((c) => c.color)),
  ('container', 'borderColor'): (
    {},
    (t) => _all<Container>(t).map(
      (c) => ((c.decoration as BoxDecoration?)?.border as Border?)?.top.color,
    ),
  ),
  ('text', 'color'): (
    {'data': 'oi'},
    (t) => [t.widget<Text>(find.text('oi')).style?.color],
  ),
  ('image', 'backgroundColor'): (
    {},
    (t) => _all<DecoratedBox>(
      t,
    ).map((d) => (d.decoration as BoxDecoration?)?.color),
  ),
  ('icon', 'color'): ({}, (t) => _all<Icon>(t).map((i) => i.color)),
  ('button', 'backgroundColor'): (
    {'label': 'Ok'},
    (t) => [_buttonStyle(t).backgroundColor?.resolve({})],
  ),
  ('button', 'foregroundColor'): (
    {'label': 'Ok'},
    (t) => [_buttonStyle(t).foregroundColor?.resolve({})],
  ),
  ('switch', 'activeColor'): (
    {},
    (t) => _all<Switch>(t).map((s) => s.activeThumbColor),
  ),
  ('checkbox', 'activeColor'): (
    {},
    (t) => _all<Checkbox>(t).map((c) => c.activeColor),
  ),
  ('card', 'color'): ({}, (t) => _all<Card>(t).map((c) => c.color)),
  ('divider', 'color'): ({}, (t) => _all<Divider>(t).map((d) => d.color)),
  ('radio', 'activeColor'): (
    {},
    (t) => _all<Radio<bool>>(t).map((r) => r.activeColor),
  ),
  ('dropdown', 'fillColor'): (
    {},
    (t) => _all<InputDecorator>(t).map((d) => d.decoration.fillColor),
  ),
  ('slider', 'activeColor'): (
    {},
    (t) => _all<Slider>(t).map((s) => s.activeColor),
  ),
};

Future<void> _pump(WidgetTester tester, SduiNode node, {ProjectTheme? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SduiView(node: node, theme: theme ?? kDefaultProjectTheme),
        ),
      ),
    );

void main() {
  test('a tabela cobre exatamente as props de cor do catálogo', () {
    final catalogColorProps = {
      for (final descriptor in widgetCatalog.values)
        for (final field in descriptor.fields)
          if (field.kind == FieldKind.color) (descriptor.type, field.key),
    };

    expect(_cases.keys.toSet(), catalogColorProps);
  });

  for (final MapEntry(key: (type, key), value: (props, read))
      in _cases.entries) {
    testWidgets('\$theme em $type.$key desenha a cor do tema injetado', (
      tester,
    ) async {
      await _pump(
        tester,
        SduiNode(id: 'n1', type: type, properties: {...props, key: _themed}),
        theme: _theme,
      );

      expect(tester.takeException(), isNull);
      expect(read(tester), contains(_accent));
    });
  }

  testWidgets('papel desconhecido sai como prop ausente e os irmãos aparecem', (
    tester,
  ) async {
    Future<Color?> colorOf(Map<String, dynamic> textProps) async {
      await _pump(
        tester,
        SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(id: 't1', type: 'text', properties: textProps),
            const SduiNode(
              id: 't2',
              type: 'text',
              properties: {'data': 'irmão'},
            ),
          ],
        ),
        theme: _theme,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('irmão'), findsOneWidget);
      return DefaultTextStyle.of(
        tester.element(find.text('alvo')),
      ).style.merge(tester.widget<Text>(find.text('alvo')).style).color;
    }

    final unknown = await colorOf({
      'data': 'alvo',
      'color': {r'$theme': 'brand'},
    });
    final absent = await colorOf({'data': 'alvo'});

    expect(unknown, absent);
    expect(unknown, isNot(_accent));
  });
}
