import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel/publication_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final publishedAt = DateTime.utc(2026, 8, 16, 12);

  Future<void> pumpBadge(
    WidgetTester tester, {
    required DateTime? publishedAt,
    required bool hasUnpublishedChanges,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PublicationBadge(
            publishedAt: publishedAt,
            hasUnpublishedChanges: hasUnpublishedChanges,
          ),
        ),
      ),
    );
  }

  testWidgets('publicado e em dia: "No ar" com ícone e tooltip', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      publishedAt: publishedAt,
      hasUnpublishedChanges: false,
    );

    expect(find.text('No ar'), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(
      find.byTooltip('No ar — o que está publicado bate com o rascunho'),
      findsOneWidget,
    );
  });

  testWidgets('publicado com alterações pendentes: tooltip diz a nuance', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      publishedAt: publishedAt,
      hasUnpublishedChanges: true,
    );

    expect(find.text('No ar'), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(
      find.byTooltip('No ar, com alterações ainda não publicadas'),
      findsOneWidget,
    );
  });

  testWidgets('nunca publicado: "Rascunho" com outro ícone e outro tooltip', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      publishedAt: null,
      hasUnpublishedChanges: true,
    );

    expect(find.text('Rascunho'), findsOneWidget);
    expect(find.text('No ar'), findsNothing);
    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.byTooltip('Nunca publicado'), findsOneWidget);
  });

  group('acessibilidade', () {
    testWidgets('cada estado tem rótulo semântico com o estado e a nuance', (
      tester,
    ) async {
      await pumpBadge(
        tester,
        publishedAt: publishedAt,
        hasUnpublishedChanges: true,
      );

      expect(
        find.bySemanticsLabel(
          'No ar: No ar, com alterações ainda não publicadas',
        ),
        findsOneWidget,
      );

      await pumpBadge(
        tester,
        publishedAt: null,
        hasUnpublishedChanges: true,
      );

      expect(
        find.bySemanticsLabel('Rascunho: Nunca publicado'),
        findsOneWidget,
      );
    });

    testWidgets('publicado e rascunho não se distinguem só pela cor', (
      tester,
    ) async {
      await pumpBadge(
        tester,
        publishedAt: publishedAt,
        hasUnpublishedChanges: false,
      );
      final publishedIcon = tester.widget<Icon>(find.byType(Icon));
      final publishedLabel = tester.widget<Text>(find.byType(Text)).data;

      await pumpBadge(
        tester,
        publishedAt: null,
        hasUnpublishedChanges: true,
      );
      final draftIcon = tester.widget<Icon>(find.byType(Icon));
      final draftLabel = tester.widget<Text>(find.byType(Text)).data;

      expect(publishedIcon.icon, isNot(draftIcon.icon));
      expect(publishedLabel, isNot(draftLabel));
    });
  });
}
