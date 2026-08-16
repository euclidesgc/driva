import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(DevicePreset device) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: DeviceStatusBar(device: device)),
  );

  testWidgets('relógio fixo em 9:41, não DateTime.now() (D29) — o golden não '
      'pode ficar não-determinístico', (tester) async {
    await tester.pumpWidget(harness(DevicePreset.smartphone));
    await tester.pump();

    expect(find.text('9:41'), findsOneWidget);
    expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
    expect(find.byIcon(Icons.battery_full), findsOneWidget);
  });

  for (final device in DevicePreset.values) {
    testWidgets(
      'preset ${device.label}: a altura é exatamente o safeAreaTop dele',
      (tester) async {
        await tester.pumpWidget(harness(device));
        await tester.pump();

        final height = tester.getSize(find.byType(DeviceStatusBar)).height;
        expect(height, device.safeAreaTop);
      },
    );
  }
}
