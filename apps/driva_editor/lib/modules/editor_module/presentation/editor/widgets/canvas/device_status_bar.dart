import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:flutter/material.dart';

/// Relógio, sinal, wifi e bateria da status bar do mock (D29). Não pinta
/// fundo — desenha só os ícones sobre o que já está atrás, para não mascarar
/// um fundo de página que no aparelho real os apagaria (item 43).
class DeviceStatusBar extends StatelessWidget {
  const DeviceStatusBar({required this.device, super.key});

  final DevicePreset device;

  @override
  Widget build(BuildContext context) {
    final mock = Theme.of(context).extension<DeviceMockColors>()!;
    return SizedBox(
      width: double.infinity,
      height: device.safeAreaTop,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mock.statusBarClockLabel,
              style: TextStyle(
                color: mock.statusBarIcon,
                fontSize: AppTypography.base,
                fontWeight: mock.statusBarClockWeight,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: AppIconSizes.s14,
                  color: mock.statusBarIcon,
                ),
                const SizedBox(width: AppSpacing.s4),
                Icon(
                  Icons.wifi,
                  size: AppIconSizes.s14,
                  color: mock.statusBarIcon,
                ),
                const SizedBox(width: AppSpacing.s4),
                Icon(
                  Icons.battery_full,
                  size: AppIconSizes.s14,
                  color: mock.statusBarIcon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
