import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/load_version_into_draft_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? result;

  setUp(() => result = null);

  Future<void> openDialog(
    WidgetTester tester, {
    required String entryLabel,
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
                    entryLabel: entryLabel,
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
      await openDialog(tester, entryLabel: 'a versão 4', isDirty: true);

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
      await openDialog(tester, entryLabel: 'a versão 4', isDirty: true);

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
      await openDialog(tester, entryLabel: 'a versão 4', isDirty: true);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('rascunho limpo', () {
    testWidgets('confirma com Carregar no rascunho, sem falar em descartar', (
      tester,
    ) async {
      await openDialog(tester, entryLabel: 'a versão 4', isDirty: false);

      expect(
        find.widgetWithText(FilledButton, 'Carregar no rascunho'),
        findsOneWidget,
      );
      expect(find.textContaining('Descartar'), findsNothing);
    });
  });

  group('ponto salvo', () {
    testWidgets('o título usa o rótulo do checkpoint, não "versão"', (
      tester,
    ) async {
      await openDialog(
        tester,
        entryLabel: 'o ponto salvo "Ponto salvo — 15/08/2026 18:00"',
        isDirty: false,
      );

      expect(
        find.text(
          'Carregar o ponto salvo "Ponto salvo — 15/08/2026 18:00" no '
          'rascunho?',
        ),
        findsOneWidget,
      );
    });
  });
}
