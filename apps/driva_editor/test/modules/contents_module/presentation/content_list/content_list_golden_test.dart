import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/content_list_page.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app_fonts.dart';

class MockContentListCubit extends MockCubit<ContentListState>
    implements ContentListCubit {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

// Goldens dos estados visuais estáveis da lista de conteúdos. As fontes reais
// do app são carregadas em setUpAll para o baseline não sair com "tofu"/Ahem.
//
// Limitação conhecida: o antialiasing/hinting das fontes reais varia ~2-3%
// entre contextos de execução (suíte completa x arquivo isolado). Para o golden
// não ficar flaky, comparamos com uma tolerância pequena (5%): ele ainda pega
// regressões estruturais/de layout (badge do slug sumindo, empty state trocado),
// mas ignora o ruído subpixel de fonte. Baseline gerado com `--update-goldens`.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    final previous = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(
      previous.basedir,
      threshold: 0.05,
    );
  });

  final content = ContentSummary(
    id: 'ct_1',
    name: 'Home — vitrine',
    slug: 'home',
    description: 'Página inicial do app do cliente.',
    updatedAt: DateTime(2026, 7, 1),
  );

  Future<void> pumpAt(WidgetTester tester, ContentListState state) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cubit = MockContentListCubit();
    whenListen(
      cubit,
      const Stream<ContentListState>.empty(),
      initialState: state,
    );
    final themeCubit = MockThemeCubit();
    whenListen(
      themeCubit,
      const Stream<ThemeState>.empty(),
      initialState: const ThemeState(AppThemeMode.light),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ContentListCubit>.value(value: cubit),
            BlocProvider<ThemeCubit>.value(value: themeCubit),
          ],
          child: const ContentListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden: card de conteúdo (slug em destaque + ID de suporte)', (
    tester,
  ) async {
    await pumpAt(tester, ContentListLoaded(contents: [content]));

    await expectLater(
      find.byType(ContentListPage),
      matchesGoldenFile('goldens/content_list_loaded.png'),
    );
  });

  testWidgets('golden: empty state', (tester) async {
    await pumpAt(tester, const ContentListEmpty());

    await expectLater(
      find.byType(ContentListPage),
      matchesGoldenFile('goldens/content_list_empty.png'),
    );
  });
}

/// Comparador de golden que aceita uma diferença até [threshold] (0..1) — o
/// suficiente para absorver o ruído subpixel das fontes reais sem mascarar
/// regressões visuais reais. Falha (com output de diff) acima do limite.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(Uri baseDir, {required this.threshold})
    : super(baseDir.resolve('placeholder_test.dart'));

  final double threshold;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= threshold) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
