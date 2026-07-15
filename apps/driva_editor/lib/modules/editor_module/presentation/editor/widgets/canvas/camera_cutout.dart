import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radii.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/device_mock_colors.dart';
import '../../device_preset.dart';

/// Recorte da câmera sobre a tela: pill central ou furo pequeno (punch-hole).
class CameraCutout extends StatelessWidget {
  const CameraCutout({super.key, required this.notch});

  final DeviceNotch notch;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<DeviceMockColors>()!.notch;
    return switch (notch) {
      DeviceNotch.pill => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s10),
          child: Container(
            width: 90,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.r13),
            ),
          ),
        ),
      ),
      DeviceNotch.punchHole => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s12),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    };
  }
}
