import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/camera_cutout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_frame.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(DevicePreset device, {required Widget child}) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: DeviceFrame(
          device: device,
          highlighted: false,
          child: child,
        ),
      ),
    ),
  );

  const marker = Key('content-marker');
  const markerWidget = Align(
    alignment: Alignment.topLeft,
    child: SizedBox(key: marker, width: 10, height: 10),
  );

  testWidgets(
    'desenhar a status bar não empurra o conteúdo (D29): o topo do '
    'conteúdo e o topo da faixa desenhada ficam no mesmo y',
    (tester) async {
      await tester.pumpWidget(
        harness(DevicePreset.smartphone, child: markerWidget),
      );
      await tester.pump();

      final barTop = tester.getTopLeft(find.byType(DeviceStatusBar)).dy;
      final contentTop = tester.getTopLeft(find.byKey(marker)).dy;
      expect(contentTop, barTop);
    },
  );

  testWidgets(
    'o SafeArea ganha causa visível (8f): sem ele o conteúdo passa por '
    'baixo do relógio, com ele começa abaixo da faixa — os dois y têm de '
    'ser distintos, na diferença exata do safeAreaTop do preset',
    (tester) async {
      await tester.pumpWidget(
        harness(DevicePreset.smartphone, child: markerWidget),
      );
      await tester.pump();
      final withoutSafeArea = tester.getTopLeft(find.byKey(marker)).dy;

      await tester.pumpWidget(
        harness(
          DevicePreset.smartphone,
          child: const SafeArea(child: markerWidget),
        ),
      );
      await tester.pump();
      final withSafeArea = tester.getTopLeft(find.byKey(marker)).dy;

      expect(withSafeArea, isNot(withoutSafeArea));
      expect(
        withSafeArea - withoutSafeArea,
        closeTo(DevicePreset.smartphone.safeAreaTop, 0.5),
      );
    },
  );

  for (final device in DevicePreset.values) {
    testWidgets(
      'preset ${device.label}: relógio e ícones não colidem com o recorte '
      'da câmera',
      (tester) async {
        await tester.pumpWidget(
          harness(device, child: const SizedBox.shrink()),
        );
        await tester.pump();

        final cutout = tester.getRect(
          find.descendant(
            of: find.byType(CameraCutout),
            matching: find.byType(Container),
          ),
        );
        final clock = tester.getRect(find.text('9:41'));
        final battery = tester.getRect(find.byIcon(Icons.battery_full));

        expect(clock.overlaps(cutout), isFalse);
        expect(battery.overlaps(cutout), isFalse);
      },
    );
  }
}
