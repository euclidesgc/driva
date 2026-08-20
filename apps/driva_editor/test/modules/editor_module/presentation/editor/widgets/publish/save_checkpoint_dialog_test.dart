import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/publish/save_checkpoint_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String?> _open(WidgetTester tester) async {
  String? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: context,
                builder: (_) => const SaveCheckpointDialog(),
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
  return result;
}

void main() {
  testWidgets('sem nota, não dá para marcar: o botão nasce desabilitado', (
    tester,
  ) async {
    await _open(tester);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Salvar e marcar'),
    );
    expect(
      button.onPressed,
      isNull,
      reason:
          'um ponto sem nota fica indistinguível de qualquer outro save no '
          'histórico — que é justamente o que marcar deveria evitar',
    );
  });

  testWidgets('só espaço em branco também não habilita', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Salvar e marcar'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('com nota, devolve o texto sem espaços nas pontas', (
    tester,
  ) async {
    String? devolvido;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                devolvido = await showDialog<String>(
                  context: context,
                  builder: (_) => const SaveCheckpointDialog(),
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

    await tester.enterText(find.byType(TextField), '  antes do banner  ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar e marcar'));
    await tester.pumpAndSettle();

    expect(devolvido, 'antes do banner');
  });

  testWidgets('a tela diz que marcar não é publicar', (tester) async {
    await _open(tester);

    expect(
      find.textContaining('não vai ao ar'),
      findsOneWidget,
      reason:
          'salvar e publicar são verbos diferentes, e confundi-los é o erro '
          'que este fluxo mais pode induzir',
    );
  });

  testWidgets('cancelar não devolve nota', (tester) async {
    String? devolvido = 'sujo';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                devolvido = await showDialog<String>(
                  context: context,
                  builder: (_) => const SaveCheckpointDialog(),
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

    await tester.enterText(find.byType(TextField), 'algo');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(devolvido, isNull);
  });
}
