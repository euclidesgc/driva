import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_toolbar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/fit_scale.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas_panel.dart';
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

void main() {
  late EditorCubit cubit;

  const document = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
  );

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
      publishContentUseCase: _MockPublishContentUseCase(),
      unpublishContentUseCase: _MockUnpublishContentUseCase(),
      restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
      projectId: 'p1',
    )..emit(const EditorReady(document: document));
  });

  tearDown(() => cubit.close());

  Widget harness({
    required Size viewport,
    required DevicePreset device,
    required double zoom,
    required bool fitToWindow,
    ValueChanged<double>? onChangeZoom,
    VoidCallback? onToggleFitToWindow,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<EditorCubit>.value(
          value: cubit,
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: CanvasPanel(
              device: device,
              zoom: zoom,
              fitToWindow: fitToWindow,
              onSelect: (_) {},
              onChangeDevice: (_) {},
              onChangeZoom: onChangeZoom ?? (_) {},
              onToggleFitToWindow: onToggleFitToWindow ?? () {},
              onDropOnDevice: (_) {},
              onDropOnNode: (_, _) {},
              isFullscreen: false,
              onToggleFullscreen: () {},
            ),
          ),
        ),
      ),
    );
  }

  double effectiveScaleShown(WidgetTester tester) =>
      tester.widget<CanvasToolbar>(find.byType(CanvasToolbar)).effectiveScale;

  group('fitToWindow ligado', () {
    testWidgets(
      'Tablet num viewport baixo (altura de canvas restrita, como sobra de '
      'uma janela ~1024×720 com topo/breadcrumb/toolbar já descontados): a '
      'moldura cabe inteira e a barra mostra escala abaixo de 40% — não '
      'passou pelo piso 0.4 do zoom manual (D9)',
      (tester) async {
        const viewport = Size(900, 550);
        await tester.pumpWidget(
          harness(
            viewport: viewport,
            device: DevicePreset.tablet,
            zoom: 0.9,
            fitToWindow: true,
          ),
        );
        await tester.pump();

        final shown = effectiveScaleShown(tester);
        expect(shown, lessThan(0.4));

        final frame = DevicePreset.tablet.frameSize;
        expect(shown * frame.width, lessThanOrEqualTo(viewport.width));
        expect(shown * frame.height, lessThanOrEqualTo(viewport.height));
      },
    );

    testWidgets(
      'é reativo: redimensionar o viewport sem chamar changeZoom recalcula '
      'a escala sozinho',
      (tester) async {
        var changeZoomCalls = 0;
        await tester.pumpWidget(
          harness(
            viewport: const Size(1440, 900),
            device: DevicePreset.tablet,
            zoom: 0.9,
            fitToWindow: true,
            onChangeZoom: (_) => changeZoomCalls++,
          ),
        );
        await tester.pump();
        final wide = effectiveScaleShown(tester);

        await tester.pumpWidget(
          harness(
            viewport: const Size(700, 500),
            device: DevicePreset.tablet,
            zoom: 0.9,
            fitToWindow: true,
            onChangeZoom: (_) => changeZoomCalls++,
          ),
        );
        await tester.pump();
        final narrow = effectiveScaleShown(tester);

        expect(narrow, lessThan(wide));
        expect(changeZoomCalls, 0);
      },
    );
  });

  group('manual vence (P5)', () {
    testWidgets(
      'fitToWindow desligado: a barra mostra o zoom manual, não o fit',
      (tester) async {
        const viewport = Size(900, 550);
        await tester.pumpWidget(
          harness(
            viewport: viewport,
            device: DevicePreset.tablet,
            zoom: 0.6,
            fitToWindow: false,
          ),
        );
        await tester.pump();

        expect(effectiveScaleShown(tester), 0.6);
        expect(
          fitScaleFor(frame: DevicePreset.tablet.frameSize, viewport: viewport),
          isNot(0.6),
        );
      },
    );

    testWidgets(
      'clique em "Ajustar à janela" dispara onToggleFitToWindow',
      (tester) async {
        var toggled = false;
        await tester.pumpWidget(
          harness(
            viewport: const Size(1000, 800),
            device: DevicePreset.smartphone,
            zoom: 0.9,
            fitToWindow: false,
            onToggleFitToWindow: () => toggled = true,
          ),
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Ajustar à janela'));
        expect(toggled, isTrue);
      },
    );
  });

  group('modo de comparação lado a lado', () {
    testWidgets(
      'compareModeBar atravessa toda a largura da área de comparação, não '
      'só o pane da candidata',
      (tester) async {
        const viewport = Size(1600, 900);
        const barKey = Key('compare-mode-bar-stub');

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: BlocProvider<EditorCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: viewport.width,
                  height: viewport.height,
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
                    compareBuilder: (scale, {required sideBySide}) =>
                        const SizedBox(),
                    compareModeBar: const ColoredBox(
                      key: barKey,
                      color: Colors.transparent,
                      child: SizedBox(height: AppSizes.canvasToolbarHeight),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final panelWidth = tester.getSize(find.byType(CanvasPanel)).width;
        final barWidth = tester.getSize(find.byKey(barKey)).width;
        expect(
          barWidth,
          closeTo(panelWidth, 0.5),
          reason:
              'a barra do modo de comparação precisa atravessar a largura '
              'inteira do canvas, não só a metade do pane da candidata',
        );
      },
    );
  });
}
