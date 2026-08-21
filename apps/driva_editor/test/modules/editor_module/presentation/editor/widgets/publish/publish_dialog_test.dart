import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/publish/publish_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final publishedWithChanges = PublicationState(
    publishedVersion: 2,
    publishedAt: DateTime.utc(2026, 8, 16, 12),
    hasUnpublishedChanges: true,
  );

  final publishedUpToDate = PublicationState(
    publishedVersion: 5,
    publishedAt: DateTime.utc(2026, 8, 16, 12),
    hasUnpublishedChanges: false,
  );

  const neverPublished = PublicationState(hasUnpublishedChanges: true);

  PublishDialogResult? result;
  var closed = false;

  setUp(() {
    result = null;
    closed = false;
  });

  Future<void> openDialog(
    WidgetTester tester, {
    required PublicationState publication,
    int warningsCount = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<PublishDialogResult>(
                  context: context,
                  builder: (_) => PublishDialog(
                    publication: publication,
                    warningsCount: warningsCount,
                  ),
                );
                closed = true;
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

  group('versão que será criada', () {
    testWidgets('publicado com alterações: anuncia a próxima versão', (
      tester,
    ) async {
      await openDialog(tester, publication: publishedWithChanges);

      expect(
        find.text('Isso cria a versão 3 e ela passa a ser a versão publicada.'),
        findsOneWidget,
      );
    });

    testWidgets('nunca publicado: a próxima versão é a 1', (tester) async {
      await openDialog(tester, publication: neverPublished);

      expect(
        find.text('Isso cria a versão 1 e ela passa a ser a versão publicada.'),
        findsOneWidget,
      );
    });

    testWidgets('sem mudança: confirma manter a versão já publicada', (
      tester,
    ) async {
      await openDialog(tester, publication: publishedUpToDate);

      expect(find.textContaining('Sem mudança'), findsOneWidget);
      expect(find.textContaining('a v5 publicada'), findsOneWidget);
      expect(find.textContaining('Isso cria a versão'), findsNothing);
    });
  });

  group('avisos não bloqueantes', () {
    testWidgets('sem avisos: nenhuma contagem na tela', (tester) async {
      await openDialog(tester, publication: publishedWithChanges);

      expect(find.textContaining('aviso'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('um aviso: contagem no singular com ícone', (tester) async {
      await openDialog(
        tester,
        publication: publishedWithChanges,
        warningsCount: 1,
      );

      expect(
        find.text(
          '1 aviso não bloqueante neste documento — não impede publicar.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('vários avisos: contagem no plural, publicar segue possível', (
      tester,
    ) async {
      await openDialog(
        tester,
        publication: publishedWithChanges,
        warningsCount: 3,
      );

      expect(
        find.text(
          '3 avisos não bloqueantes neste documento — não impedem publicar.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  });

  group('nota opcional', () {
    testWidgets('o campo respeita o limite de 200 do DTO', (tester) async {
      await openDialog(tester, publication: publishedWithChanges);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, 200);
      expect(find.text('0/200'), findsOneWidget);
    });

    testWidgets('publicar sem nota devolve note nulo', (tester) async {
      await openDialog(tester, publication: publishedWithChanges);

      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNotNull);
      expect(result!.note, isNull);
    });

    testWidgets('publicar com nota devolve o texto sem espaços nas pontas', (
      tester,
    ) async {
      await openDialog(tester, publication: publishedWithChanges);

      await tester.enterText(find.byType(TextField), '  ajuste do banner  ');
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();

      expect(result!.note, 'ajuste do banner');
    });

    testWidgets('cancelar não devolve resultado nenhum', (tester) async {
      await openDialog(tester, publication: publishedWithChanges);

      await tester.enterText(find.byType(TextField), 'não vai subir');
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}
