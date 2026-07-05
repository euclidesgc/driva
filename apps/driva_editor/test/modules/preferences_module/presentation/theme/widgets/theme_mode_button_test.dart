import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockThemeCubit cubit;

  setUp(() {
    cubit = MockThemeCubit();
    registerFallbackValue(AppThemeMode.system);
  });

  Widget harness(AppThemeMode mode) {
    whenListen(
      cubit,
      const Stream<ThemeState>.empty(),
      initialState: ThemeState(mode),
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            BlocProvider<ThemeCubit>.value(
              value: cubit,
              child: const ThemeModeButton(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('mostra ícone e tooltip do modo atual (sinal além da cor)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(AppThemeMode.dark));

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byTooltip('Tema: escuro (toque para sistema)'), findsOneWidget);
  });

  testWidgets('tem semântica de botão anunciando estado e próxima ação', (
    tester,
  ) async {
    await tester.pumpWidget(harness(AppThemeMode.light));

    expect(
      find.bySemanticsLabel('Tema: claro. Toque para escuro.'),
      findsOneWidget,
    );
  });

  testWidgets('toque avança claro → escuro', (tester) async {
    when(() => cubit.setMode(any())).thenAnswer((_) async {});
    await tester.pumpWidget(harness(AppThemeMode.light));

    await tester.tap(find.byType(ThemeModeButton));

    verify(() => cubit.setMode(AppThemeMode.dark)).called(1);
  });
}
