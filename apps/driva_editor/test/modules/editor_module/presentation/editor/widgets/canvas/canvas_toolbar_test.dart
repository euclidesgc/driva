import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required double effectiveScale,
  required bool fitToWindow,
  required ValueChanged<double> onChangeZoom,
  bool isFullscreen = false,
  VoidCallback? onToggleFullscreen,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: CanvasToolbar(
      device: DevicePreset.tablet,
      effectiveScale: effectiveScale,
      fitToWindow: fitToWindow,
      onChangeDevice: (_) {},
      onChangeZoom: onChangeZoom,
      onToggleFitToWindow: () {},
      onOpenPreview: () {},
      isFullscreen: isFullscreen,
      onToggleFullscreen: onToggleFullscreen ?? () {},
    ),
  ),
);

void main() {
  testWidgets(
    'ajuste automático no piso do clamp manual (D9): o "−" fica desabilitado '
    'e não dispara onChangeZoom',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          effectiveScale: 0.31,
          fitToWindow: true,
          onChangeZoom: (_) => calls++,
        ),
      );
      await tester.pump();

      final zoomOutButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.zoom_out),
      );
      expect(zoomOutButton.onPressed, isNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.zoom_out));
      await tester.pump();

      expect(calls, 0);
    },
  );

  testWidgets(
    'ajuste automático acima do piso: o "−" continua habilitado',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          effectiveScale: 0.6,
          fitToWindow: true,
          onChangeZoom: (_) => calls++,
        ),
      );
      await tester.pump();

      final zoomOutButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.zoom_out),
      );
      expect(zoomOutButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.zoom_out));
      expect(calls, 1);
    },
  );

  testWidgets(
    'zoom manual (fitToWindow desligado) no mesmo piso: o "−" continua '
    'habilitado — a trava é só do ajuste automático',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          effectiveScale: 0.4,
          fitToWindow: false,
          onChangeZoom: (_) => calls++,
        ),
      );
      await tester.pump();

      final zoomOutButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.zoom_out),
      );
      expect(zoomOutButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.zoom_out));
      expect(calls, 1);
    },
  );

  group('tela cheia (F7/D16)', () {
    testWidgets(
      'o botão está sempre visível e mostra o ícone de entrar quando fora '
      'do modo',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            effectiveScale: 0.9,
            fitToWindow: true,
            onChangeZoom: (_) {},
          ),
        );
        await tester.pump();

        expect(find.byTooltip('Tela cheia'), findsOneWidget);
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      },
    );

    testWidgets('ligado, mostra o ícone de sair e o tooltip menciona o Esc', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          effectiveScale: 0.9,
          fitToWindow: true,
          onChangeZoom: (_) {},
          isFullscreen: true,
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Sair da tela cheia (Esc)'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });

    testWidgets('tocar o botão dispara onToggleFullscreen', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          effectiveScale: 0.9,
          fitToWindow: true,
          onChangeZoom: (_) {},
          onToggleFullscreen: () => calls++,
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Tela cheia'));

      expect(calls, 1);
    });
  });
}
