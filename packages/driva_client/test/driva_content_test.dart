import 'dart:async';
import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sdui_core/sdui_core.dart';

const Map<String, dynamic> _rootTextNodeJson = {
  'id': 'home-text',
  'type': 'text',
  'props': {'data': 'Conteúdo carregado'},
};

const Map<String, dynamic> _specWithRootJson = {
  'specVersion': 1,
  'kind': 'content',
  'id': 'home-id',
  'name': 'Home',
  'slug': 'home',
  'root': _rootTextNodeJson,
};

Map<String, dynamic> _envelope(Map<String, dynamic> spec) => {
  'id': 'home-id',
  'name': 'Home',
  'slug': 'home',
  'updatedAt': DateTime.now().toIso8601String(),
  'spec': spec,
};

const Map<String, dynamic> _themedSpecJson = {
  'specVersion': 2,
  'kind': 'content',
  'id': 'home-id',
  'name': 'Home',
  'slug': 'home',
  'root': {
    'id': 'themed-text',
    'type': 'text',
    'props': {
      'data': 'Texto do tema',
      'color': {r'$theme': 'primary'},
    },
  },
};

Color _colorFromHex(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// `SduiSafeArea` liga `SafeArea` por padrão (`enabled: true`), que exige
/// `MediaQuery`/`Directionality` no ancestral — o par que `MaterialApp` +
/// `Scaffold` fornece.
Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(Driva.resetForTesting);
  tearDown(Driva.resetForTesting);

  group('DrivaContent', () {
    testWidgets(
      'exibe o loadingBuilder antes da primeira emissão e o conteúdo do '
      'spec após a resposta 200',
      (tester) async {
        final responseCompleter = Completer<http.Response>();
        final client = MockClient((request) => responseCompleter.future);

        await Driva.init(
          DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        await tester.pumpWidget(
          _harness(
            DrivaContent(
              slug: 'home',
              loadingBuilder: (context) =>
                  const SizedBox(key: Key('driva-loading')),
            ),
          ),
        );

        expect(find.byKey(const Key('driva-loading')), findsOneWidget);
        expect(find.byKey(const ValueKey('home-text')), findsNothing);

        responseCompleter.complete(
          http.Response(jsonEncode(_envelope(_specWithRootJson)), 200),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('home-text')), findsOneWidget);
        expect(find.byKey(const Key('driva-loading')), findsNothing);
      },
    );

    testWidgets(
      'sem cache e sem fallback, resposta 404 entrega DrivaLoadFailure '
      '(notFound) ao errorBuilder',
      (tester) async {
        final client = MockClient((request) async => http.Response('', 404));

        await Driva.init(
          DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        Object? capturedError;
        await tester.pumpWidget(
          _harness(
            DrivaContent(
              slug: 'home',
              errorBuilder: (context, error) {
                capturedError = error;
                return const SizedBox(key: Key('driva-error'));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('driva-error')), findsOneWidget);
        expect(capturedError, isA<DrivaLoadFailure>());
        expect(
          (capturedError! as DrivaLoadFailure).cause,
          DrivaLoadCause.notFound,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'falha total sem errorBuilder cai em SizedBox.shrink e não deixa '
      'exceção escapar',
      (tester) async {
        final client = MockClient((request) async => http.Response('', 500));

        await Driva.init(
          DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        await tester.pumpWidget(_harness(const DrivaContent(slug: 'home')));
        await tester.pumpAndSettle();

        final drivaContent = find.byType(DrivaContent);
        expect(drivaContent, findsOneWidget);
        final shrunkBox = find.descendant(
          of: drivaContent,
          matching: find.byType(SizedBox),
        );
        expect(shrunkBox, findsOneWidget);
        final box = tester.widget<SizedBox>(shrunkBox);
        expect(box.width, 0.0);
        expect(box.height, 0.0);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group(r'DrivaContent: tema do projeto ($theme)', () {
    Future<Color?> pumpThemedText(
      WidgetTester tester,
      Map<String, dynamic> envelope,
    ) async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode(envelope), 200),
      );
      await Driva.init(
        DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      await tester.pumpWidget(_harness(const DrivaContent(slug: 'home')));
      await tester.pumpAndSettle();

      return tester.widget<Text>(find.text('Texto do tema')).style?.color;
    }

    testWidgets('desenha o primary do tema do projeto', (tester) async {
      final color = await pumpThemedText(tester, {
        ..._envelope(_themedSpecJson),
        'theme': {
          'colors': {'primary': '#FF0000'},
        },
      });

      expect(color, const Color(0xFFFF0000));
    });

    testWidgets('sem tema desenha o primary do tema padrão', (tester) async {
      final color = await pumpThemedText(tester, _envelope(_themedSpecJson));

      expect(
        color,
        _colorFromHex(kDefaultProjectTheme.colors[ThemeColorRole.primary]!),
      );
    });
  });
}
