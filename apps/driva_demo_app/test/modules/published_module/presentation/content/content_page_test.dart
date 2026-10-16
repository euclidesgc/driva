import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/page/content_page.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_key_missing_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_not_found_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget _harness(Widget child) => MaterialApp(home: child);

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
}
