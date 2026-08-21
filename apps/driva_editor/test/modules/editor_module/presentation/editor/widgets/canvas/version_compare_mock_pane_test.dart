import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_unsafe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockEditorCubit extends MockCubit<EditorState> implements EditorCubit {}

const _draftSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': 'rascunho ao vivo'},
  ),
);

const _candidateSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'n_root',
    type: 'text',
    properties: {'text': 'como era na v3'},
  ),
);

Widget _harness({
  required Size surface,
  required EditorCubit editorCubit,
  bool comparing = true,
  CanvasCompareSide side = CanvasCompareSide.draft,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: BlocProvider<EditorCubit>.value(
      value: editorCubit,
      child: SizedBox(
        width: surface.width,
        height: surface.height,
        child: CanvasPanel(
          device: DevicePreset.smartphone,
          zoom: 0.9,
          fitToWindow: true,
          onSelect: (_) {},
          onChangeDevice: (_) {},
          onChangeZoom: (_) {},
          onToggleFitToWindow: () {},
          onDropOnDevice: (_) {},
          onDropOnNode: (_, _) {},
          isFullscreen: false,
          onToggleFullscreen: () {},
          compareSide: side,
          onCompareSideChanged: (_) {},
          compareBuilder: comparing
              ? (scale) => VersionCompareMockPane(
                  device: DevicePreset.smartphone,
                  effectiveScale: scale,
                  spec: _candidateSpec,
                  candidateVersion: 3,
                  onOlder: () {},
                  onNewer: () {},
                  onClose: () {},
                )
              : null,
        ),
      ),
    ),
  ),
);

void main() {
  late _MockEditorCubit editorCubit;

  setUp(() {
    editorCubit = _MockEditorCubit();
    when(() => editorCubit.state).thenReturn(
      const EditorReady(document: _draftSpec),
    );
    whenListen(
      editorCubit,
      const Stream<EditorState>.empty(),
      initialState: const EditorReady(document: _draftSpec),
    );
  });

  testWidgets(
    'fora do modo de comparação o canvas mostra um mock só, e nenhum '
    'alternador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          surface: const Size(1600, 900),
          editorCubit: editorCubit,
          comparing: false,
        ),
      );
      await tester.pump();

      expect(find.byType(DeviceFrame), findsOneWidget);
      expect(find.byType(CanvasCompareSideToggle), findsNothing);
      expect(find.byType(VersionCompareMockPane), findsNothing);
    },
  );

  testWidgets(
    'com espaço de sobra, comparar mostra os dois mocks lado a lado, na '
    'mesma escala',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(surface: const Size(1600, 900), editorCubit: editorCubit),
      );
      await tester.pump();

      expect(find.byType(DeviceFrame), findsNWidgets(2));
      expect(find.byType(CanvasCompareSideToggle), findsNothing);

      final draftRect = tester.getRect(find.byType(DeviceFrame).first);
      final candidateRect = tester.getRect(find.byType(DeviceFrame).last);
      expect(
        draftRect.width,
        closeTo(candidateRect.width, 0.5),
        reason: 'mocks de tamanhos diferentes não se comparam a olho',
      );
      expect(
        draftRect.right,
        lessThan(candidateRect.left),
        reason: 'o rascunho fica à esquerda e a versão à direita',
      );
    },
  );

  testWidgets(
    'em janela estreita cai para um mock por vez, com alternador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 380));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(surface: const Size(440, 380), editorCubit: editorCubit),
      );
      await tester.pump();

      expect(find.byType(DeviceFrame), findsOneWidget);
      expect(find.byType(CanvasCompareSideToggle), findsOneWidget);
    },
  );

  testWidgets(
    'na faixa estreita, o alternador escolhe qual mock aparece',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 380));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          surface: const Size(440, 380),
          editorCubit: editorCubit,
          side: CanvasCompareSide.candidate,
        ),
      );
      await tester.pump();

      expect(find.byType(VersionCompareMockPane), findsOneWidget);
      expect(find.byType(CanvasDraftMock), findsNothing);
      expect(find.byTooltip('Fechar comparação'), findsOneWidget);
    },
  );

  testWidgets(
    'o mock da versão é inerte e fica fora do alvo de arraste do rascunho',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(surface: const Size(1600, 900), editorCubit: editorCubit),
      );
      await tester.pump();

      expect(find.byType(VersionCompareInertPreview), findsOneWidget);
      expect(
        find.byType(DragTarget<DragPayload>),
        findsWidgets,
        reason:
            'os alvos de arraste do rascunho precisam existir para a '
            'asserção seguinte significar alguma coisa',
      );
      expect(
        find.descendant(
          of: find.byType(DragTarget<DragPayload>),
          matching: find.byType(VersionCompareMockPane),
        ),
        findsNothing,
        reason:
            'dentro do DragTarget do rascunho, soltar um widget da paleta '
            'sobre a versão histórica o adicionaria ao rascunho',
      );
    },
  );

  _paneEdgeTests();
}

void _paneEdgeTests() {
  testWidgets(
    'ID duplicado bloqueia a comparação: o lugar do mock explica por quê, e '
    'não há moldura a mais',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: VersionCompareMockPane(
              device: DevicePreset.smartphone,
              effectiveScale: 0.8,
              spec: _candidateSpec,
              candidateVersion: 3,
              onOlder: () {},
              onNewer: () {},
              onClose: () {},
              unsafeView: const VersionCompareUnsafeView(
                failure: DuplicateNodeIdComparisonFailure(
                  baseDuplicateIds: {'nd_1'},
                  candidateDuplicateIds: {},
                ),
                onLoadFullVersion: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VersionCompareUnsafeView), findsOneWidget);
      expect(
        find.byType(DeviceFrame),
        findsNothing,
        reason:
            'com a comparação bloqueada não há o que mostrar na moldura — '
            'exibi-la sugeriria que a comparação vale',
      );
    },
  );

  testWidgets(
    'nas pontas do histórico, a navegação de versão fica desabilitada',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: VersionCompareMockPane(
              device: DevicePreset.smartphone,
              effectiveScale: 0.8,
              spec: _candidateSpec,
              candidateVersion: 3,
              onOlder: null,
              onNewer: null,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final older = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      final newer = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(
        older.onPressed,
        isNull,
        reason:
            'na versão mais antiga carregada e sem próxima página, não há '
            'para onde descer',
      );
      expect(
        newer.onPressed,
        isNull,
        reason: 'na versão mais nova do histórico, não há para onde subir',
      );
    },
  );
}

void _noop() {}
