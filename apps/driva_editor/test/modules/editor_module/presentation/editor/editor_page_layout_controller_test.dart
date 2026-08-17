import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/editor_page.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockPublishContentUseCase extends Mock
    implements PublishContentUseCase {}

class _MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class _MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class _MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late EditorCubit cubit;
  late _MockThemeCubit themeCubit;

  setUp(() {
    cubit =
        EditorCubit(
          loadContentUseCase: _MockLoadContentUseCase(),
          saveDraftUseCase: _MockSaveDraftUseCase(),
          publishContentUseCase: _MockPublishContentUseCase(),
          unpublishContentUseCase: _MockUnpublishContentUseCase(),
          restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
          projectId: 'p1',
        )..emit(
          const EditorReady(
            document: ContentSpec(
              specVersion: kSpecVersion,
              id: 'ct_1',
              name: 'Home',
              slug: 'home',
              root: SduiNode(
                id: 'nd_root',
                type: 'text',
                properties: {'data': 'A'},
              ),
            ),
          ),
        );
    themeCubit = _MockThemeCubit();
    whenListen(
      themeCubit,
      const Stream<ThemeState>.empty(),
      initialState: const ThemeState(AppThemeMode.light),
    );
  });

  tearDown(() => cubit.close());

  Widget harness({EditorLayoutController? layoutController}) => MaterialApp(
    theme: AppTheme.light,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<EditorCubit>.value(value: cubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: EditorPage(
        projectFuture: Future<Either<Failure, Project>>.value(
          const Left(UnexpectedFailure()),
        ),
        layoutController: layoutController,
      ),
    ),
  );

  void enlarge(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'D19 — sem layoutController informado, a página monta sem exceção '
    '(editor_perf_test e canvas_panel_golden_test dependem disto)',
    (tester) async {
      enlarge(tester);
      await tester.pumpWidget(harness());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'um layoutController recebido pelo construtor não é descartado quando '
    'a EditorPage desmonta — ele não é dono',
    (tester) async {
      enlarge(tester);
      final external = EditorLayoutController();
      addTearDown(external.dispose);

      await tester.pumpWidget(harness(layoutController: external));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());

      expect(external.collapseLeftPanel, returnsNormally);
    },
  );
}
