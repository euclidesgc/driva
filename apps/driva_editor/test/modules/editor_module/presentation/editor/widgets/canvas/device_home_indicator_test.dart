import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_home_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(DevicePreset device) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: DeviceHomeIndicator(device: device)),
  );

  for (final device in DevicePreset.values) {
    testWidgets(
      'preset ${device.label}: a faixa tem a altura do safeAreaBottom dele, '
      'e a cápsula fica centralizada com a largura do token',
      (tester) async {
        await tester.pumpWidget(harness(device));
        await tester.pump();

        final barHeight = tester
            .getSize(find.byType(DeviceHomeIndicator))
            .height;
        expect(barHeight, device.safeAreaBottom);

        final capsule = tester.getSize(find.byType(Container));
        expect(capsule.width, AppSizes.deviceHomeIndicatorWidth);
        expect(capsule.height, AppSizes.deviceHomeIndicatorHeight);
      },
    );
  }
}
