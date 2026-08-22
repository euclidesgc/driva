import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
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

final _candidate = LoadedContentVersion(
  version: 3,
  spec: _candidateSpec,
  createdAt: DateTime.utc(2026, 8, 16),
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
              ? (scale, {required sideBySide}) => VersionCompareMockPane(
                  device: DevicePreset.smartphone,
                  effectiveScale: scale,
                  spec: _candidateSpec,
                  candidate: _candidate,
                  showBar: !sideBySide,
                  onOlder: () {},
                  onNewer: () {},
                  onLoadFullVersion: () {},
                  onClose: () {},
                )
              : null,
          compareModeBar: comparing ? const _StubCompareModeBar() : null,
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
    'mesma escala e na mesma altura',
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
        draftRect.height,
        closeTo(candidateRect.height, 1),
        reason:
            'a moldura do rascunho e a da candidata precisam da mesma '
            'proporção — escalas diferentes enganam a comparação',
      );
      expect(
        draftRect.right,
        lessThan(candidateRect.left),
        reason: 'o rascunho fica à esquerda e a versão à direita',
      );
    },
  );

  testWidgets(
    'nenhum dos dois DeviceFrame sai espremido: a proporção larg/alt de '
    'cada um bate com a do preset, e os dois tamanhos batem entre si',
    (tester) async {
      // Viewport deliberadamente estreito (mas acima do piso de
      // AppSizes.canvasCompareMinSplitScale, então ainda cabem os dois
      // mocks lado a lado): com espaço de sobra (1600×900, como no teste
      // acima) a largura por painel folga bem além da largura natural do
      // preset e o espremido não aparece — foi exatamente essa folga que
      // deixou o bug escapar da bateria anterior.
      const surface = Size(760, 900);
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(surface: surface, editorCubit: editorCubit),
      );
      await tester.pump();

      final frames = find.byType(DeviceFrame);
      expect(frames, findsNWidgets(2));

      final presetRatio =
          DevicePreset.smartphone.frameSize.width /
          DevicePreset.smartphone.frameSize.height;
      final draftSize = tester.getSize(frames.first);
      final candidateSize = tester.getSize(frames.last);

      expect(
        draftSize.width / draftSize.height,
        closeTo(presetRatio, 0.001),
        reason:
            'a moldura do rascunho precisa manter a proporção do preset do '
            'device',
      );
      expect(
        candidateSize.width / candidateSize.height,
        closeTo(presetRatio, 0.001),
        reason:
            'a moldura da versão comparada não pode sair espremida — '
            'regressão do bug em que o DeviceFrame da direita era forçado '
            'a uma largura menor que a do preset, com a mesma altura do '
            'rascunho',
      );
      expect(
        draftSize.width,
        closeTo(candidateSize.width, 0.5),
        reason:
            'os dois lados reusam a mesma cadeia de layout e não podem '
            'divergir de tamanho',
      );
      expect(
        draftSize.height,
        closeTo(candidateSize.height, 0.5),
        reason:
            'os dois lados reusam a mesma cadeia de layout e não podem '
            'divergir de tamanho',
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
              candidate: _candidate,
              onOlder: () {},
              onNewer: () {},
              onLoadFullVersion: () {},
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
              candidate: _candidate,
              onOlder: null,
              onNewer: null,
              onLoadFullVersion: () {},
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

class _StubCompareModeBar extends StatelessWidget {
  const _StubCompareModeBar();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: AppSizes.canvasToolbarHeight);
}
