import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? result;

  setUp(() => result = null);

  Future<void> openDialog(
    WidgetTester tester, {
    required int version,
    required bool isDirty,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => LoadVersionIntoDraftConfirmDialog(
                    version: version,
                    isDirty: isDirty,
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('rascunho sujo', () {
    testWidgets('oferece só Descartar e Cancelar — nunca Salvar antes', (
      tester,
    ) async {
      await openDialog(tester, version: 4, isDirty: true);

      expect(
        find.widgetWithText(
          FilledButton,
          'Descartar alterações locais e carregar',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
      expect(find.textContaining('Salvar antes'), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('descartar devolve true', (tester) async {
      await openDialog(tester, version: 4, isDirty: true);

      await tester.tap(
        find.widgetWithText(
          FilledButton,
          'Descartar alterações locais e carregar',
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancelar devolve false', (tester) async {
      await openDialog(tester, version: 4, isDirty: true);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('rascunho limpo', () {
    testWidgets('confirma com Carregar no rascunho, sem falar em descartar', (
      tester,
    ) async {
      await openDialog(tester, version: 4, isDirty: false);

      expect(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
        findsOneWidget,
      );
      expect(find.textContaining('Descartar'), findsNothing);
    });
  });
}
