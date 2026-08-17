import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _erro = SpecDiagnostic(
  nodeId: 'nd_sp',
  nodeType: 'spacer',
  code: DiagnosticCode.flexOnlyOutsideFlex,
  severity: DiagnosticSeverity.error,
  message: 'Spacer só funciona dentro de uma Row ou Column.',
);

const _aviso = SpecDiagnostic(
  nodeId: 'nd_pad',
  nodeType: 'padding',
  code: DiagnosticCode.emptySingleSlot,
  severity: DiagnosticSeverity.warning,
  message: 'Padding está sem filho e não desenha nada.',
);

Future<void> _pump(
  WidgetTester tester, {
  List<SpecDiagnostic> diagnostics = const [],
  EditorNotice? notice,
  ValueChanged<String>? onSelectNode,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: EditorStatusBar(
            diagnostics: diagnostics,
            notice: notice,
            onSelectNode: onSelectNode ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('documento saudável anuncia que não há problema', (tester) async {
    await _pump(tester);

    expect(find.text('Nenhum problema'), findsOneWidget);
    expect(find.byType(DiagnosticRow), findsNothing);
  });

  testWidgets('conta erros e avisos separadamente', (tester) async {
    await _pump(tester, diagnostics: const [_erro, _aviso]);

    expect(find.text('1 erro · 1 aviso'), findsOneWidget);
  });

  testWidgets('a lista começa fechada e abre no clique do resumo', (
    tester,
  ) async {
    await _pump(tester, diagnostics: const [_erro, _aviso]);
    expect(find.byType(DiagnosticRow), findsNothing);

    await tester.tap(find.byType(StatusBarSummary));
    await tester.pumpAndSettle();

    expect(find.byType(DiagnosticRow), findsNWidgets(2));
    expect(find.text(_erro.message), findsOneWidget);
  });

  testWidgets('clicar num problema seleciona o nó culpado', (tester) async {
    String? selecionado;
    await _pump(
      tester,
      diagnostics: const [_erro],
      onSelectNode: (id) => selecionado = id,
    );

    await tester.tap(find.byType(StatusBarSummary));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DiagnosticRow));

    expect(selecionado, 'nd_sp');
  });

  testWidgets('sem problema não há o que abrir (resumo não é clicável)', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      tester.widget<StatusBarSummary>(find.byType(StatusBarSummary)).onToggle,
      isNull,
    );
  });

  testWidgets('o recado do último arraste aparece ao lado do resumo', (
    tester,
  ) async {
    await _pump(
      tester,
      notice: const EditorNotice(
        kind: EditorNoticeKind.dropRedirected,
        sequence: 1,
        subjectType: 'text',
      ),
    );

    expect(find.textContaining('Text não recebe esse widget'), findsOneWidget);
  });

  testWidgets('o recado de envolver widget aparece ao lado do resumo', (
    tester,
  ) async {
    await _pump(
      tester,
      notice: const EditorNotice(
        kind: EditorNoticeKind.nodeWrapped,
        sequence: 1,
        subjectType: 'column',
      ),
    );

    expect(find.text('Envolvido numa Column.'), findsOneWidget);
  });

  testWidgets(
    'sem o tipo do wrapper, o recado de envolver cai no padrão Column',
    (tester) async {
      await _pump(
        tester,
        notice: const EditorNotice(
          kind: EditorNoticeKind.nodeWrapped,
          sequence: 1,
        ),
      );

      expect(find.text('Envolvido numa Column.'), findsOneWidget);
    },
  );

  testWidgets('o recado de agrupamento do drop aparece ao lado do resumo', (
    tester,
  ) async {
    await _pump(
      tester,
      notice: const EditorNotice(
        kind: EditorNoticeKind.dropWrapped,
        sequence: 1,
        subjectType: 'text',
        wrapperType: 'column',
      ),
    );

    expect(
      find.text(
        'Text não recebia esse widget — os dois foram agrupados numa Column.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'o rótulo do wrapper cai no tipo bruto quando o catálogo não o conhece',
    (tester) async {
      await _pump(
        tester,
        notice: const EditorNotice(
          kind: EditorNoticeKind.dropWrapped,
          sequence: 1,
          subjectType: 'text',
          wrapperType: 'no_such_widget',
        ),
      );

      expect(
        find.text(
          'Text não recebia esse widget — os dois foram agrupados numa '
          'no_such_widget.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('a lista aberta se fecha sozinha quando o problema some', (
    tester,
  ) async {
    await _pump(tester, diagnostics: const [_erro]);
    await tester.tap(find.byType(StatusBarSummary));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticRow), findsOneWidget);

    await _pump(tester);

    expect(find.byType(DiagnosticRow), findsNothing);
    expect(find.text('Nenhum problema'), findsOneWidget);
  });
}
