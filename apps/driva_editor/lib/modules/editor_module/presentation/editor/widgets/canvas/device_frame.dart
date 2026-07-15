import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/device_mock_colors.dart';
import '../../device_preset.dart';
import 'camera_cutout.dart';
import 'side_button.dart';

/// Moldura realista do dispositivo: corpo metálico com bezel, cantos
/// arredondados, botões laterais e recorte de câmera (pill/punch-hole)
/// derivados do [DevicePreset]. Puramente visual — desenhada com
/// decorations/`CustomPaint`, sem dependência externa. A tela (a `child`) é
/// clipada com as dimensões e o raio de cantos do device.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.device,
    required this.highlighted,
    required this.child,
  });

  final DevicePreset device;
  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mock = Theme.of(context).extension<DeviceMockColors>()!;
    final bezel = device.bezel;
    final bodyRadius = device.cornerRadius + bezel;
    final buttonWidth = bezel * 0.55;

    return Semantics(
      label:
          'Moldura ${device.label} (${device.width.toInt()}'
          '×${device.height.toInt()})',
      child: Padding(
        // Espaço para os botões laterais transbordarem o corpo.
        padding: EdgeInsets.symmetric(horizontal: buttonWidth),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SideButton(
              alignment: Alignment.centerLeft,
              width: buttonWidth,
              color: mock.button,
              top: device.height * 0.20,
              length: device.height * 0.10,
            ),
            SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: mock.button,
              top: device.height * 0.16,
              length: device.height * 0.06,
            ),
            SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: mock.button,
              top: device.height * 0.26,
              length: device.height * 0.12,
            ),
            Container(
              padding: EdgeInsets.all(bezel),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [mock.bodyGradientTop, mock.body],
                ),
                borderRadius: BorderRadius.circular(bodyRadius),
                border: Border.all(color: mock.rim, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: mock.shadow,
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                  if (highlighted)
                    BoxShadow(
                      color: mock.glow,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(device.cornerRadius),
                    child: SizedBox(
                      width: device.width,
                      height: device.height,
                      child: ColoredBox(color: mock.screen, child: child),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CameraCutout(notch: device.notch),
                    ),
                  ),
                  if (highlighted)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              device.cornerRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
