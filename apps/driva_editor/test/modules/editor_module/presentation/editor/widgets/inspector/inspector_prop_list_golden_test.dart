import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  testWidgets('golden: inspector de um Column com seções e resumo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(340, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: InspectorPropList(
            node: const SduiNode(
              id: 'n1',
              type: 'column',
              properties: {
                'mainAxisAlignment': 'spaceBetween',
                'crossAxisAlignment': 'stretch',
                'spacing': 12.0,
              },
            ),
            descriptor: descriptorFor('column')!,
            onUpdateProps: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(InspectorPropList),
      matchesGoldenFile('goldens/inspector_prop_list_column.png'),
    );
  });

  testWidgets('golden: seção fechada mostra o resumo no cabeçalho', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(340, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: InspectorPropList(
            node: const SduiNode(
              id: 'n1',
              type: 'text',
              properties: {
                'data': 'Semana do cliente',
                'fontSize': 18.0,
                'fontWeight': 'w700',
              },
            ),
            descriptor: descriptorFor('text')!,
            onUpdateProps: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ESTILO'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(InspectorPropList),
      matchesGoldenFile('goldens/inspector_prop_list_collapsed.png'),
    );
  });
}
