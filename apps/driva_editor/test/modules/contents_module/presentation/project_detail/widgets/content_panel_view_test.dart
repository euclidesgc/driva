import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/app_fonts.dart';

class MockContentListCubit extends MockCubit<ContentListState>
    implements ContentListCubit {}

void main() {
  setUpAll(loadAppFonts);

  final content = ContentSummary(
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    categoryId: 'cat_1',
    updatedAt: DateTime(2026, 7, 1),
  );

  late MockContentListCubit cubit;

  setUp(() {
    cubit = MockContentListCubit();
    // O `initState` do painel lê a ordenação corrente do cubit.
    when(() => cubit.currentSort).thenReturn(ContentSort.updatedAt);
    when(() => cubit.currentOrder).thenReturn(ContentSortOrder.desc);
  });

  Widget bootstrap({
    required ContentListState state,
    Map<String, String> categoryNameById = const {},
  }) {
    whenListen(
      cubit,
      const Stream<ContentListState>.empty(),
      initialState: state,
    );
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<ContentListCubit>.value(
          value: cubit,
          child: ContentPanelView(
            categoryLabel: 'Geral',
            categoryNameById: categoryNameById,
            onOpenContent: (_) {},
            onNewContent: () {},
            onEditContent: (_) {},
            onMoveContent: (_) {},
            onDeleteContent: (_) {},
          ),
        ),
      ),
    );
  }

  group('rótulo de categoria no card de grade', () {
    testWidgets('mostra o nome da categoria quando resolve pelo mapa', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        bootstrap(
          state: ContentListLoaded(contents: [content]),
          categoryNameById: const {'cat_1': 'Geral'},
        ),
      );

      // Título do card + rótulo de categoria (ambos "Geral": um no card,
      // outro no header do painel — por isso findsWidgets).
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Geral'), findsWidgets);
    });

    testWidgets('omite a linha quando o mapa está vazio (árvore carregando)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        bootstrap(
          state: ContentListLoaded(contents: [content]),
          categoryNameById: const {},
        ),
      );

      // Sem ícone de pasta: a linha inteira foi omitida...
      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      // ...mas o card segue renderizando título e slug normalmente.
      expect(find.text('Home'), findsWidgets);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('omite a linha quando o categoryId não está no mapa', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        bootstrap(
          state: ContentListLoaded(contents: [content]),
          categoryNameById: const {'cat_outra': 'Marketing'},
        ),
      );

      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      expect(find.text('Marketing'), findsNothing);
      expect(find.text('Home'), findsWidgets);
    });
  });

  group('modo lista', () {
    testWidgets('não exibe a categoria mesmo com o mapa preenchido', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        bootstrap(
          state: ContentListLoaded(contents: [content]),
          categoryNameById: const {'cat_1': 'Geral'},
        ),
      );

      // Alterna grade -> lista pelo toggle de visualização.
      await tester.tap(find.byTooltip('Lista'));
      await tester.pumpAndSettle();

      // A linha de categoria (ícone de pasta) só existe no card de grade.
      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      // O conteúdo continua listado (título presente).
      expect(find.text('Home'), findsWidgets);
    });
  });

  group('acessibilidade', () {
    testWidgets('expõe Semantics "Categoria: <nome>" quando resolve', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        bootstrap(
          state: ContentListLoaded(contents: [content]),
          categoryNameById: const {'cat_1': 'Geral'},
        ),
      );

      expect(find.bySemanticsLabel(RegExp('Categoria: Geral')), findsOneWidget);

      semantics.dispose();
    });
  });
}
