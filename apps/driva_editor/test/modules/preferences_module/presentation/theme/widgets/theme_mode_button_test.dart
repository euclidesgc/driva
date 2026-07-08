import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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

  testWidgets('mostra o icone do modo atual (sinal alem da cor)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(AppThemeMode.dark));

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byTooltip('Tema'), findsOneWidget);
  });

  testWidgets('icone usa cor de contraste da superficie', (tester) async {
    await tester.pumpWidget(harness(AppThemeMode.light));

    final icon = tester.widget<Icon>(find.byIcon(Icons.light_mode_outlined));

    expect(icon.color, AppTheme.light.colorScheme.onSurface);
  });

  testWidgets('tem semantica de botao anunciando o modo atual', (tester) async {
    await tester.pumpWidget(harness(AppThemeMode.light));

    expect(find.bySemanticsLabel('Tema — atual: Claro'), findsOneWidget);
  });

  testWidgets('abre o menu com as tres opcoes (claro/escuro/sistema)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(AppThemeMode.light));

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
  });

  testWidgets('selecionar uma opcao aplica o modo no cubit', (tester) async {
    when(() => cubit.setMode(any())).thenAnswer((_) async {});
    await tester.pumpWidget(harness(AppThemeMode.light));

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    verify(() => cubit.setMode(AppThemeMode.dark)).called(1);
  });

  testWidgets('a opcao ativa e marcada com um check', (tester) async {
    await tester.pumpWidget(harness(AppThemeMode.system));

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
