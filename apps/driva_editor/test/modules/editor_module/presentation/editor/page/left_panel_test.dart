import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/left_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

void main() {
  late EditorCubit cubit;

  const document = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
  );

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      projectId: 'p1',
    )..emit(const EditorReady(document: document));
  });

  tearDown(() => cubit.close());

  Widget harness() => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: BlocProvider<EditorCubit>.value(
        value: cubit,
        child: const SizedBox(width: 280, height: 600, child: LeftPanel()),
      ),
    ),
  );

  group('sem EditorLayoutScope acima (Fix T3)', () {
    testWidgets('monta sem crashar', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(LeftPanel), findsOneWidget);
    });

    testWidgets('o botão de recolher não aparece', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.byTooltip('Recolher painel'), findsNothing);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('as abas Widgets e Árvore continuam funcionais', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.text('Widgets'), findsOneWidget);
      expect(find.text('Árvore'), findsOneWidget);

      await tester.tap(find.text('Árvore'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
