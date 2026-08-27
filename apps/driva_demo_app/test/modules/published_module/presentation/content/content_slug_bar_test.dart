import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_slug_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required String currentSlug,
  required ValueChanged<String> onSubmit,
}) => MaterialApp(
  home: Scaffold(
    bottomNavigationBar: ContentSlugBar(
      currentSlug: currentSlug,
      onSubmit: onSubmit,
    ),
  ),
);

void main() {
  group('ContentSlugBar', () {
    testWidgets(
      'submeter um slug novo chama onSubmit com o valor sem espaços das '
      'pontas',
      (tester) async {
        String? submitted;

        await tester.pumpWidget(
          _harness(currentSlug: 'home', onSubmit: (slug) => submitted = slug),
        );

        await tester.enterText(find.byType(TextField), '  outro-slug  ');
        await tester.tap(find.byTooltip('Abrir slug'));
        await tester.pump();

        expect(submitted, 'outro-slug');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('submeter vazio não chama onSubmit', (tester) async {
      var called = false;

      await tester.pumpWidget(
        _harness(currentSlug: 'home', onSubmit: (_) => called = true),
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Abrir slug'));
      await tester.pump();

      expect(called, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submeter o slug atual (sem editar) não chama onSubmit', (
      tester,
    ) async {
      var called = false;

      await tester.pumpWidget(
        _harness(currentSlug: 'home', onSubmit: (_) => called = true),
      );

      // O controller já inicia preenchido com o slug atual — reenviar sem
      // editar não deve disparar onSubmit.
      await tester.tap(find.byTooltip('Abrir slug'));
      await tester.pump();

      expect(called, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
