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
        expect(tester.takeException(), isNull);
      },
    );
  });
}
