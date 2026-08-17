import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A barra tem de caber no piso real do painel central (`minCenterWidth`, 320),
/// não só em janela confortável: abaixo de `workspaceMinimumWidth` o workspace
/// passa a rolar, mas o centro já chegou nos 320.
void main() {
  for (final width in const [
    320.0,
    360.0,
    420.0,
    459.0,
    460.0,
    520.0,
    579.0,
    580.0,
    649.0,
    650.0,
    700.0,
    900.0,
  ]) {
    testWidgets('não estoura em ${width}px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: CanvasToolbar(
                device: DevicePreset.smartphone,
                effectiveScale: 0.84,
                fitToWindow: false,
                onChangeDevice: (_) {},
                onChangeZoom: (_) {},
                onToggleFitToWindow: () {},
                onOpenPreview: () {},
                isFullscreen: false,
                onToggleFullscreen: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'overflow em ${width}px');
    });
  }

  testWidgets('em faixa estreita, nenhuma ação some — vão para o menu', (
    tester,
  ) async {
    var previewed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: CanvasToolbar(
              device: DevicePreset.smartphone,
              effectiveScale: 0.84,
              fitToWindow: false,
              onChangeDevice: (_) {},
              onChangeZoom: (_) {},
              onToggleFitToWindow: () {},
              onOpenPreview: () => previewed++,
              isFullscreen: false,
              onToggleFullscreen: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Ver no celular'), findsOneWidget);
    expect(find.text('Ajustar à janela'), findsOneWidget);
    expect(find.text('Tela cheia'), findsOneWidget);

    await tester.tap(find.text('Ver no celular'));
    await tester.pumpAndSettle();

    expect(previewed, 1);
  });
}
