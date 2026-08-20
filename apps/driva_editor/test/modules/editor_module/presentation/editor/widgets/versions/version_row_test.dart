import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final version = ContentVersion(
    version: 3,
    createdAt: DateTime.utc(2026, 8, 16, 12),
    note: 'Ajuste no banner',
  );

  Future<void> pumpRow(
    WidgetTester tester, {
    ValueChanged<int>? onView,
    ValueChanged<int>? onLoadToDraft,
    ValueChanged<int>? onCompare,
    bool isPublished = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: VersionRow(
          version: version,
          isPublished: isPublished,
          onView: onView ?? (_) {},
          onLoadToDraft: onLoadToDraft ?? (_) {},
          onCompare: onCompare,
        ),
      ),
    ),
  );

  testWidgets('oferece Ver, Comparar e Carregar no rascunho', (tester) async {
    await pumpRow(tester);

    expect(find.widgetWithText(FilledButton, 'Ver'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Comparar'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
      findsOneWidget,
    );
  });

  testWidgets('Ver é a ação primária (tonal), as outras não', (tester) async {
    await pumpRow(tester);

    final ver = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ver'),
    );
    expect(ver.onPressed, isNotNull);
  });

  testWidgets('Comparar fica desabilitada sem onCompare (T4 pendente)', (
    tester,
  ) async {
    await pumpRow(tester);

    final comparar = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Comparar'),
    );
    expect(comparar.onPressed, isNull);
  });

  testWidgets('Comparar liga quando onCompare é passado', (tester) async {
    var compared = 0;
    await pumpRow(tester, onCompare: (_) => compared++);

    final comparar = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Comparar'),
    );
    expect(comparar.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Comparar'));
    expect(compared, 1);
  });

  testWidgets('Ver chama onView com o número da versão', (tester) async {
    int? viewed;
    await pumpRow(tester, onView: (v) => viewed = v);

    await tester.tap(find.widgetWithText(FilledButton, 'Ver'));

    expect(viewed, 3);
  });

  testWidgets('Carregar no rascunho chama onLoadToDraft com o número da '
      'versão', (tester) async {
    int? loaded;
    await pumpRow(tester, onLoadToDraft: (v) => loaded = v);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Carregar no rascunho'),
    );

    expect(loaded, 3);
  });

  testWidgets('selecionar a linha (sem tocar nenhum botão) não chama nada', (
    tester,
  ) async {
    var calls = 0;
    await pumpRow(
      tester,
      onView: (_) => calls++,
      onLoadToDraft: (_) => calls++,
      onCompare: (_) => calls++,
    );

    await tester.tap(find.text('Versão 3'));

    expect(calls, 0);
  });
}
