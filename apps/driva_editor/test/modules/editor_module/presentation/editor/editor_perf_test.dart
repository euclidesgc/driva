import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

ContentSpec _docWithText(String text) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      SduiNode(id: 'nd_text', type: 'text', properties: {'data': text}),
    ],
  ),
);

void main() {
  late EditorCubit cubit;
  late _MockThemeCubit themeCubit;

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
    );
    cubit.emit(EditorReady(document: _docWithText('A')));
    themeCubit = _MockThemeCubit();
    whenListen(
      themeCubit,
      const Stream<ThemeState>.empty(),
      initialState: const ThemeState(AppThemeMode.light),
    );
  });

  tearDown(() => cubit.close());

  Widget harness() => MaterialApp(
    theme: AppTheme.light,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<EditorCubit>.value(value: cubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: const EditorPage(),
    ),
  );

  void enlarge(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('editor pronto monta os três painéis', (tester) async {
    enlarge(tester);
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('Widgets'), findsOneWidget); // aba da paleta
    expect(find.text('Árvore'), findsOneWidget);
    expect(find.text('Conteúdo'), findsWidgets); // header do inspector (root)
    expect(find.text('A'), findsOneWidget); // preview renderiza o texto
  });

  testWidgets('o preview throttla edições rápidas do documento', (
    tester,
  ) async {
    enlarge(tester);
    await tester.pumpWidget(harness());
    await tester.pump();
    expect(find.text('A'), findsOneWidget);

    // O listener do preview reage ao stream numa microtask; o segundo pump
    // constrói o frame com o resultado do setState.
    Future<void> react() async {
      await tester.pump();
      await tester.pump();
    }

    // 1ª mudança: sem cooldown ativo → aplica imediatamente.
    cubit.updateProps('nd_text', {'data': 'B'});
    await react();
    expect(find.text('B'), findsOneWidget);

    // 2ª mudança dentro da janela do throttle: fica pendente; o preview
    // ainda mostra 'B' (não re-renderiza a cada tecla).
    cubit.updateProps('nd_text', {'data': 'C'});
    await react();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);

    // Passada a janela, o render final ('C') aparece — nada é perdido.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(find.text('C'), findsOneWidget);
    expect(find.text('B'), findsNothing);
  });

  testWidgets('a seleção reflete no preview na hora (sem throttle)', (
    tester,
  ) async {
    enlarge(tester);
    await tester.pumpWidget(harness());
    await tester.pump();

    cubit.selectNode('nd_text');
    await tester.pump();

    // O inspector passa a mostrar o nó Text selecionado (não mais 'Conteúdo').
    expect(find.text('Text'), findsWidgets);
  });
}
