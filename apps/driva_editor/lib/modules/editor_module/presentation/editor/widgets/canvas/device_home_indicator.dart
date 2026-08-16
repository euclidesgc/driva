import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:flutter/material.dart';

/// Cápsula do indicador de home da status bar do mock (D29). Simétrico à
/// [DeviceStatusBar]: não pinta fundo, só a cápsula sobre o que está atrás.
class DeviceHomeIndicator extends StatelessWidget {
  const DeviceHomeIndicator({required this.device, super.key});

  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    final mock = Theme.of(context).extension<DeviceMockColors>()!;
    return SizedBox(
      width: double.infinity,
      height: device.safeAreaBottom,
      child: Center(
        child: Container(
          width: AppSizes.deviceHomeIndicatorWidth,
          height: AppSizes.deviceHomeIndicatorHeight,
          decoration: BoxDecoration(
            color: mock.homeIndicator,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),
    );
  }
}
