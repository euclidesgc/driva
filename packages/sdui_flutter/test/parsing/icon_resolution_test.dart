import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

void main() {
  test('parseIconRef: sem prefixo é material', () {
    expect(parseIconRef('home'), (library: 'material', name: 'home'));
    expect(parseIconRef('a:b'), (library: 'a', name: 'b'));
  });

  test('formato antigo e novo resolvem igual', () {
    expect(iconDataFrom('home'), Icons.home);
    expect(iconDataFrom('material:home'), Icons.home);
  });

  test('desconhecido mostra fallback sem lançar', () {
    expect(iconDataFrom('material:naoexiste'), isNull);
    expect(iconDataOrFallback('material:naoexiste'), iconFallback);
    expect(iconDataOrFallback('outra:x'), iconFallback);
    expect(iconDataOrFallback(null), isNull);
    expect(iconDataOrFallback(3), isNull);
  });

  testWidgets('Icon com nome desconhecido renderiza o fallback', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(iconDataOrFallback('outra:x')),
      ),
    );
    expect(tester(t), findsOneWidget);
  });
}

Finder tester(WidgetTester t) => find.byIcon(iconFallback);
