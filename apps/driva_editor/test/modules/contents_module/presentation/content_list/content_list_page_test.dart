import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:fpdart/fpdart.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/content_list_page.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/app_fonts.dart';

class MockContentListCubit extends MockCubit<ContentListState>
    implements ContentListCubit {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  setUpAll(loadAppFonts);

  final content = ContentSummary(
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    description: 'Vitrine principal',
    updatedAt: DateTime(2026, 7, 1),
  );

  late MockContentListCubit cubit;
  late MockThemeCubit themeCubit;

  setUp(() {
    cubit = MockContentListCubit();
    themeCubit = MockThemeCubit();
    whenListen(
      themeCubit,
      const Stream<ThemeState>.empty(),
      initialState: const ThemeState(AppThemeMode.light),
    );
  });

  Widget bootstrap(ContentListState state) {
    whenListen(
      cubit,
      const Stream<ContentListState>.empty(),
      initialState: state,
    );
    return MaterialApp(
      theme: AppTheme.light,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ContentListCubit>.value(value: cubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: const ContentListPage(),
      ),
    );
  }

  group('estados do sealed', () {
    testWidgets('Loading mostra o progress indicator', (tester) async {
      await tester.pumpWidget(bootstrap(const ContentListLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Empty mostra a orientação de primeiro uso e o CTA', (
      tester,
    ) async {
      await tester.pumpWidget(bootstrap(const ContentListEmpty()));

      expect(
        find.text('Nenhum conteúdo ainda. Crie o primeiro.'),
        findsOneWidget,
      );
      expect(
        find.text('Monte-o arrastando widgets no editor.'),
        findsOneWidget,
      );
      // CTA na barra + CTA no corpo vazio.
      expect(find.text('Novo conteúdo'), findsNWidgets(2));
    });

    testWidgets('Error mostra a mensagem tipada e o botão de retentar', (
      tester,
    ) async {
      await tester.pumpWidget(
        bootstrap(const ContentListError(failure: NetworkFailure())),
      );

      expect(
        find.text('Sem conexão com o servidor. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('Error: tocar "Tentar de novo" reexecuta o load do cubit', (
      tester,
    ) async {
      when(() => cubit.load()).thenAnswer((_) async {});
      await tester.pumpWidget(
        bootstrap(const ContentListError(failure: NetworkFailure())),
      );

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();

      verify(() => cubit.load()).called(1);
    });

    testWidgets('Loaded renderiza o card com nome, slug e descrição', (
      tester,
    ) async {
      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );

      expect(find.text('Home'), findsWidgets);
      expect(find.text('home'), findsOneWidget);
      expect(find.text('Vitrine principal'), findsOneWidget);
      expect(find.text('ID de suporte: ct_1'), findsOneWidget);
    });
  });

  group('acessibilidade do card (cor não é o único sinal)', () {
    testWidgets('slug e ID de suporte expõem rótulo textual via Semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );

      expect(
        find.bySemanticsLabel(RegExp('Slug do conteúdo: home')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('ID de suporte: ct_1')),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('a ação de excluir tem tooltip descritivo', (tester) async {
      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );

      expect(find.byTooltip('Excluir conteúdo'), findsOneWidget);
    });
  });

  group('exclusão otimista', () {
    Future<void> confirmDelete(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Excluir conteúdo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pump();
    }

    testWidgets('confirmar exclusão chama delete do cubit com o id do card', (
      tester,
    ) async {
      when(
        () => cubit.delete('ct_1'),
      ).thenAnswer((_) async => const Right(unit));

      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );
      await confirmDelete(tester);

      verify(() => cubit.delete('ct_1')).called(1);
    });

    testWidgets('falha ao excluir exibe snackbar de erro', (tester) async {
      when(
        () => cubit.delete('ct_1'),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );
      await confirmDelete(tester);
      await tester.pump();

      expect(
        find.text('Não foi possível excluir. Tente de novo.'),
        findsOneWidget,
      );
    });
  });

  group('diálogo "Novo conteúdo"', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Novo conteúdo').first);
      await tester.pumpAndSettle();
    }

    testWidgets('digitar o Nome deriva o slug ao vivo (com sanitização)', (
      tester,
    ) async {
      await tester.pumpWidget(bootstrap(const ContentListEmpty()));
      await openDialog(tester);

      // Campo 0 = Nome, campo 1 = Slug, campo 2 = Descrição.
      await tester.enterText(find.byType(TextFormField).at(0), 'Página Início');
      await tester.pump();

      expect(find.text('pagina-inicio'), findsOneWidget);
    });

    testWidgets('derivação evita colisão com slug existente (home → home-2)', (
      tester,
    ) async {
      await tester.pumpWidget(
        bootstrap(ContentListLoaded(contents: [content])),
      );
      await openDialog(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Home');
      await tester.pump();

      expect(find.text('home-2'), findsOneWidget);
    });

    testWidgets('slug inválido é barrado na validação do cliente', (
      tester,
    ) async {
      await tester.pumpWidget(bootstrap(const ContentListEmpty()));
      await openDialog(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'X');
      // Editar o slug à mão fixa-o e passa a valer a validação do campo.
      await tester.enterText(find.byType(TextFormField).at(1), 'Slug Inválido');
      await tester.tap(find.text('Criar'));
      await tester.pump();

      expect(find.textContaining('Use letras minúsculas'), findsOneWidget);
      // O diálogo continua aberto: a validação impediu o submit.
      expect(find.text('Novo conteúdo'), findsWidgets);
      verifyNever(
        () => cubit.create(
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          description: any(named: 'description'),
        ),
      );
    });
  });
}
