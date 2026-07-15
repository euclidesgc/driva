import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden.dart';

class MockContentListCubit extends MockCubit<ContentListState>
    implements ContentListCubit {}

// Rede de caracterização por golden do painel de conteúdos (F1 do refactor):
// congela a aparência atual da grade, da lista, do estado vazio e — o estado
// crítico — do "ghost" esmaecido (opacity 0.4) enquanto um card é arrastado.
// As fontes reais são carregadas para o baseline não sair com Ahem/tofu e o
// comparador tolerante (5%) absorve o ruído subpixel sem esconder regressão.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  final contents = <ContentSummary>[
    ContentSummary(
      id: 'ct_1',
      name: 'Home — vitrine',
      slug: 'home',
      categoryId: 'cat_1',
      description: 'Página inicial do app do cliente.',
      updatedAt: DateTime(2026, 7, 1, 9, 30),
    ),
    ContentSummary(
      id: 'ct_2',
      name: 'Detalhe da oferta',
      slug: 'offer-detail',
      categoryId: 'cat_2',
      updatedAt: DateTime(2026, 6, 28, 14, 5),
    ),
    ContentSummary(
      id: 'ct_3',
      name: 'Carrinho',
      slug: 'cart',
      categoryId: 'cat_1',
      updatedAt: DateTime(2026, 6, 20, 8, 0),
    ),
  ];

  const categoryNameById = {'cat_1': 'Geral', 'cat_2': 'Marketing'};

  late MockContentListCubit cubit;

  setUp(() {
    cubit = MockContentListCubit();
    when(() => cubit.currentSort).thenReturn(ContentSort.updatedAt);
    when(() => cubit.currentOrder).thenReturn(ContentSortOrder.desc);
  });

  Future<void> pumpPanel(WidgetTester tester, ContentListState state) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    whenListen(
      cubit,
      const Stream<ContentListState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
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
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden: grade carregada', (tester) async {
    await pumpPanel(tester, ContentListLoaded(contents: contents));

    await expectLater(
      find.byType(ContentPanelView),
      matchesGoldenFile('goldens/content_panel_grid.png'),
    );
  });

  testWidgets('golden: lista carregada', (tester) async {
    await pumpPanel(tester, ContentListLoaded(contents: contents));

    await tester.tap(find.byTooltip('Lista'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ContentPanelView),
      matchesGoldenFile('goldens/content_panel_list.png'),
    );
  });

  testWidgets('golden: card esmaecido durante o arraste (ghost, opacity 0.4)', (
    tester,
  ) async {
    await pumpPanel(tester, ContentListLoaded(contents: contents));

    // Inicia um arraste real sobre o primeiro card: o `Draggable` troca o
    // filho pelo `childWhenDragging` (o mesmo card com opacity 0.4). O chip de
    // feedback vai para o Overlay do app (acima do painel), então o golden do
    // painel captura só a origem esmaecida — o estado que o refactor precisa
    // preservar pixel a pixel.
    final card = find.byType(Draggable<ContentSummary>).first;
    final gesture = await tester.startGesture(tester.getCenter(card));
    await gesture.moveBy(const Offset(24, 24));
    await tester.pump();

    await expectLater(
      find.byType(ContentPanelView),
      matchesGoldenFile('goldens/content_panel_drag_ghost.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('golden: estado vazio', (tester) async {
    await pumpPanel(tester, const ContentListEmpty());

    await expectLater(
      find.byType(ContentPanelView),
      matchesGoldenFile('goldens/content_panel_empty.png'),
    );
  });
}
