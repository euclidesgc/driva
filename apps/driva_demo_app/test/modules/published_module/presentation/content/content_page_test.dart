import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/page/content_page.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_key_missing_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_not_found_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_slug_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sdui_core/sdui_core.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

Map<String, dynamic> _action(String type, [Map<String, dynamic>? params]) => {
  'action': type,
  'params': ?params,
};

Map<String, dynamic> _navigateTo(String slug) =>
    _action('navigate', {'slug': slug});

Map<String, dynamic> _page(
  String slug,
  Map<String, Map<String, dynamic>> tappables,
) => {
  'specVersion': kSpecVersion,
  'kind': 'content',
  'id': 'ct_$slug',
  'name': slug,
  'slug': slug,
  'root': {
    'id': 'root_$slug',
    'type': 'column',
    'children': [
      for (final MapEntry(key: label, value: action) in tappables.entries)
        {
          'id': 'tap_${slug}_$label',
          'type': 'container',
          'props': {
            'width': 240,
            'height': 48,
            'color': '#DDE6FF',
          },
          'events': {
            'onTap': [action],
          },
          'child': {
            'id': 'label_${slug}_$label',
            'type': 'text',
            'props': {'data': label},
          },
        },
    ],
  },
};

Future<void> _initServing(Map<String, Map<String, dynamic>> pages) =>
    Driva.init(
      DrivaConfig(
        baseUrl: 'https://api.example.com',
        publishableKey: 'pk_test',
        cache: MemoryCacheStore(),
      ),
      httpClient: MockClient((request) async {
        final page = pages[request.url.pathSegments.last];
        return page == null
            ? http.Response('', 404)
            : http.Response(jsonEncode({'spec': page}), 200);
      }),
    );

Future<void> _pumpPage(
  WidgetTester tester, {
  Future<bool> Function(Uri url)? urlOpener,
}) async {
  await tester.pumpWidget(
    _harness(
      urlOpener == null
          ? const ContentPage(initialSlug: 'home', publishableKey: 'pk_test')
          : ContentPage(
              initialSlug: 'home',
              publishableKey: 'pk_test',
              urlOpener: urlOpener,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _title(String slug) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(slug));

void main() {
  setUp(Driva.resetForTesting);
  tearDown(Driva.resetForTesting);

  group('ContentPage', () {
    testWidgets(
      'chave placeholder (sem prefixo pk_) mostra ContentKeyMissingView e '
      'não monta nenhum DrivaContent',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            const ContentPage(
              initialSlug: 'home',
              publishableKey: 'cole-aqui-a-chave-do-projeto',
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ContentKeyMissingView), findsOneWidget);
        expect(find.byType(DrivaContent), findsNothing);
        expect(
          find.bySemanticsLabel('Chave publicável ausente'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'chave pk_ bem-formada com 404 do servidor mostra ContentNotFoundView',
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

        await tester.pumpWidget(
          _harness(
            const ContentPage(initialSlug: 'home', publishableKey: 'pk_test'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContentNotFoundView), findsOneWidget);
        // O ícone e o título compartilham o texto — o rótulo aparece duas
        // vezes na árvore de semântica (ícone + texto visível).
        expect(
          find.bySemanticsLabel('Conteúdo não encontrado'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'chave pk_ bem-formada com exceção de rede mostra ContentErrorView',
      (tester) async {
        final client = MockClient(
          (request) async => throw Exception('sem conexão'),
        );
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
            const ContentPage(initialSlug: 'home', publishableKey: 'pk_test'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContentErrorView), findsOneWidget);
        expect(
          find.bySemanticsLabel('Falha de conexão ou servidor'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'conteúdo com tipo de widget desconhecido renderiza sem estado de erro',
      (tester) async {
        final spec = {
          'specVersion': 1,
          'kind': 'content',
          'id': 'ct_1',
          'name': 'Home',
          'slug': 'home',
          'root': {
            'id': 'n1',
            'type': 'column',
            'children': [
              {
                'id': 'n2',
                'type': 'text',
                'props': {'data': 'antes'},
              },
              {'id': 'n3', 'type': 'futureWidget'},
              {
                'id': 'n4',
                'type': 'text',
                'props': {'data': 'depois'},
              },
            ],
          },
        };
        final client = MockClient(
          (request) async => http.Response(jsonEncode({'spec': spec}), 200),
        );
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
            const ContentPage(initialSlug: 'home', publishableKey: 'pk_test'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContentErrorView), findsNothing);
        expect(find.text('antes'), findsOneWidget);
        expect(find.text('depois'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'spec v2 com cor de tema desenha o primary do tema do projeto',
      (tester) async {
        final spec = {
          'specVersion': 2,
          'kind': 'content',
          'id': 'ct_1',
          'name': 'Home',
          'slug': 'home',
          'root': {
            'id': 'n1',
            'type': 'text',
            'props': {
              'data': 'Texto do tema',
              'color': {r'$theme': 'primary'},
            },
          },
        };
        final client = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'spec': spec,
              'theme': {
                'colors': {'primary': '#FF0000'},
              },
            }),
            200,
          ),
        );
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
            const ContentPage(initialSlug: 'home', publishableKey: 'pk_test'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<Text>(find.text('Texto do tema')).style?.color,
          const Color(0xFFFF0000),
        );
        expect(find.byType(ContentErrorView), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ContentPage executa as ações', () {
    testWidgets('navigate troca o slug mostrado no título', (tester) async {
      await _initServing({
        'home': _page('home', {'Promoções': _navigateTo('promocoes')}),
        'promocoes': _page('promocoes', {'Voltar': _action('navigateBack')}),
      });
      await _pumpPage(tester);

      await _tapLabel(tester, 'Promoções');

      expect(_title('promocoes'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
    });

    testWidgets('navigate para slug inexistente mostra ContentNotFoundView', (
      tester,
    ) async {
      await _initServing({
        'home': _page('home', {'Sumiu': _navigateTo('sumiu')}),
      });
      await _pumpPage(tester);

      await _tapLabel(tester, 'Sumiu');

      expect(_title('sumiu'), findsOneWidget);
      expect(find.byType(ContentNotFoundView), findsOneWidget);
    });

    testWidgets('navigateBack percorre a pilha home → a → b de volta', (
      tester,
    ) async {
      await _initServing({
        'home': _page('home', {'Ir para a': _navigateTo('a')}),
        'a': _page('a', {
          'Ir para b': _navigateTo('b'),
          'Voltar de a': _action('navigateBack'),
        }),
        'b': _page('b', {'Voltar de b': _action('navigateBack')}),
      });
      await _pumpPage(tester);

      await _tapLabel(tester, 'Ir para a');
      await _tapLabel(tester, 'Ir para b');
      expect(_title('b'), findsOneWidget);

      await _tapLabel(tester, 'Voltar de b');
      expect(_title('a'), findsOneWidget);

      await _tapLabel(tester, 'Voltar de a');
      expect(_title('home'), findsOneWidget);
    });

    testWidgets('navigateBack sem histórico mantém home', (tester) async {
      await _initServing({
        'home': _page('home', {'Voltar': _action('navigateBack')}),
      });
      await _pumpPage(tester);

      await _tapLabel(tester, 'Voltar');

      expect(_title('home'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a barra de slug limpa o histórico do navigateBack', (
      tester,
    ) async {
      await _initServing({
        'home': _page('home', {'Ir para a': _navigateTo('a')}),
        'a': _page('a', {}),
        'c': _page('c', {'Voltar de c': _action('navigateBack')}),
      });
      await _pumpPage(tester);
      await _tapLabel(tester, 'Ir para a');

      await tester.enterText(
        find.descendant(
          of: find.byType(ContentSlugBar),
          matching: find.byType(TextField),
        ),
        'c',
      );
      await tester.tap(find.byTooltip('Abrir slug'));
      await tester.pumpAndSettle();
      expect(_title('c'), findsOneWidget);

      await _tapLabel(tester, 'Voltar de c');

      expect(_title('c'), findsOneWidget);
    });

    testWidgets('showSnackBar mostra a mensagem configurada', (tester) async {
      await _initServing({
        'home': _page('home', {
          'Avisar': _action('showSnackBar', {'message': 'Cupom aplicado'}),
        }),
      });
      await _pumpPage(tester);

      await _tapLabel(tester, 'Avisar');

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Cupom aplicado'),
        ),
        findsOneWidget,
      );
    });

    group('launchUrl', () {
      final opened = <Uri>[];
      setUp(opened.clear);

      Future<void> pumpWithOpener(WidgetTester tester, {required bool result}) {
        return _pumpPage(
          tester,
          urlOpener: (url) async {
            opened.add(url);
            return result;
          },
        );
      }

      Future<void> serveSiteLink() => _initServing({
        'home': _page('home', {
          'Site': _action('launchUrl', {'url': 'https://driva.dev'}),
        }),
      });

      testWidgets('chama o urlOpener uma vez com a url configurada', (
        tester,
      ) async {
        await serveSiteLink();
        await pumpWithOpener(tester, result: true);

        await _tapLabel(tester, 'Site');

        expect(opened, [Uri.parse('https://driva.dev')]);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('com o opener devolvendo false mostra a falha', (
        tester,
      ) async {
        await serveSiteLink();
        await pumpWithOpener(tester, result: false);

        await _tapLabel(tester, 'Site');

        expect(opened, hasLength(1));
        expect(find.text('Não foi possível abrir o link.'), findsOneWidget);
      });
    });
  });
}
