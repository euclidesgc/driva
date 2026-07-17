import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:flutter/material.dart';

class CameraCutout extends StatelessWidget {
  const CameraCutout({required this.notch, super.key});

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
