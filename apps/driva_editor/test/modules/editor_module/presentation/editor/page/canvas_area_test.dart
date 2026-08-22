import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/canvas_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_draft_legend.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/return_to_published_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/return_to_published_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _MockVersionCompareModeCubit extends MockCubit<VersionCompareModeState>
    implements VersionCompareModeCubit {}

const _document = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(id: 'n_root', type: 'text', properties: {'data': 'Olá'}),
);

const _candidateSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(id: 'n_root', type: 'text', properties: {'data': 'Antes'}),
);

void main() {
  late EditorCubit cubit;
  late _MockVersionCompareModeCubit compareCubit;
  late EditorLayoutController layoutController;

  VersionCompareModeActive active() => VersionCompareModeActive(
    candidate: LoadedContentVersion(
      version: 2,
      spec: _candidateSpec,
      createdAt: DateTime.utc(2026, 8, 16),
    ),
    baseSpec: _document,
    result: compareContentSpecs(_document, _candidateSpec),
  );

  EditorReady ready({int? publishedVersion = 2}) => EditorReady(
    document: _document,
    publication: PublicationState(
      hasUnpublishedChanges: true,
      publishedVersion: publishedVersion,
    ),
  );

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    );
    compareCubit = _MockVersionCompareModeCubit();
    layoutController = EditorLayoutController();
  });

  tearDown(() => cubit.close());
  tearDown(() => layoutController.dispose());

  Future<void> pump(
    WidgetTester tester, {
    required VersionCompareModeState compareState,
    double width = 1300,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    whenListen(
      compareCubit,
      const Stream<VersionCompareModeState>.empty(),
      initialState: compareState,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<EditorCubit>.value(
            value: cubit,
            child: EditorLayoutScope(
              controller: layoutController,
              child: VersionCompareModeScope(
                cubit: compareCubit,
                child: const CanvasArea(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'modo ativo com versão publicada: legenda Rascunho e botão de voltar na '
    'barra do canvas',
    (tester) async {
      cubit.emit(ready());
      await pump(tester, compareState: active());

      expect(find.byType(CanvasCompareDraftLegend), findsOneWidget);
      expect(find.byType(ReturnToPublishedButton), findsOneWidget);
      expect(find.text('Voltar à versão publicada'), findsOneWidget);
    },
  );

  testWidgets('modo inativo: nem legenda nem botão', (tester) async {
    cubit.emit(ready());
    await pump(tester, compareState: const VersionCompareModeInactive());

    expect(find.byType(CanvasCompareDraftLegend), findsNothing);
    expect(find.byType(ReturnToPublishedButton), findsNothing);
  });

  testWidgets('modo ativo sem versão publicada: legenda sim, botão não', (
    tester,
  ) async {
    cubit.emit(ready(publishedVersion: null));
    await pump(tester, compareState: active());

    expect(find.byType(CanvasCompareDraftLegend), findsOneWidget);
    expect(find.byType(ReturnToPublishedButton), findsNothing);
  });

  testWidgets('cancelar no diálogo não dispara a volta ao publicado', (
    tester,
  ) async {
    cubit.emit(ready());
    await pump(tester, compareState: active());

    await tester.tap(find.byType(ReturnToPublishedButton));
    await tester.pumpAndSettle();
    expect(find.byType(ReturnToPublishedConfirmDialog), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => compareCubit.returnToPublished());
  });

  testWidgets('confirmar no diálogo dispara a volta ao publicado', (
    tester,
  ) async {
    cubit.emit(ready());
    when(
      () => compareCubit.returnToPublished(),
    ).thenAnswer((_) async => true);
    await pump(tester, compareState: active());

    await tester.tap(find.byType(ReturnToPublishedButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Voltar à versão publicada'),
    );
    await tester.pumpAndSettle();

    verify(() => compareCubit.returnToPublished()).called(1);
  });

  testWidgets(
    'barra estreita: o botão colapsa para ícone com tooltip e a legenda some',
    (tester) async {
      cubit.emit(ready());
      await pump(tester, compareState: active(), width: 500);

      expect(find.byType(CanvasCompareDraftLegend), findsNothing);
      expect(find.byTooltip('Voltar à versão publicada'), findsOneWidget);
      expect(find.text('Voltar à versão publicada'), findsNothing);
    },
  );
}
