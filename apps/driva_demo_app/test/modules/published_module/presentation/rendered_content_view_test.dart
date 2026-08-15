import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/rendered_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

PublishedContent _contentOf(SduiNode? root) => PublishedContent(
  spec: ContentSpec(
    specVersion: 1,
    id: 'c1',
    name: 'Vitrine',
    slug: 'vitrine',
    root: root,
  ),
  updatedAt: DateTime.utc(2026, 8, 14),
  etag: null,
);

Widget _host(PublishedContent content) => MaterialApp(
  home: Scaffold(body: RenderedContentView(content: content)),
);

void main() {
  testWidgets('renderiza a árvore que veio no spec', (tester) async {
    await tester.pumpWidget(
      _host(
        _contentOf(
          const SduiNode(
            id: 'n1',
            type: 'text',
            properties: {'data': 'servido pelo driva'},
          ),
        ),
      ),
    );

    expect(find.text('servido pelo driva'), findsOneWidget);
  });

  testWidgets('conteúdo sem root explica em vez de mostrar tela branca', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_contentOf(null)));

    expect(find.textContaining('ainda não tem widgets'), findsOneWidget);
  });

  testWidgets('evento do spec chega ao app como dado', (tester) async {
    await tester.pumpWidget(
      _host(
        _contentOf(
          const SduiNode(
            id: 'n1',
            type: 'button',
            properties: {'label': 'Tocar'},
            events: {
              'onPressed': [
                {
                  'action': 'showMessage',
                  'params': {'text': 'veio do spec'},
                },
              ],
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tocar'));
    await tester.pump();

    expect(find.textContaining('showMessage'), findsOneWidget);
  });
}
