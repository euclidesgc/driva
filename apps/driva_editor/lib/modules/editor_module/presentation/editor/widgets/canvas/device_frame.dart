import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
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

  static const _bodyColor = Color(0xFF1B1D21);
  static const _rimColor = Color(0xFF3A3D44);
  static const _buttonColor = Color(0xFF2A2D33);

  @override
  Widget build(BuildContext context) {
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
              color: _buttonColor,
              top: device.height * 0.20,
              length: device.height * 0.10,
            ),
            SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: _buttonColor,
              top: device.height * 0.16,
              length: device.height * 0.06,
            ),
            SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: _buttonColor,
              top: device.height * 0.26,
              length: device.height * 0.12,
            ),
            Container(
              padding: EdgeInsets.all(bezel),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF25282E), _bodyColor],
                ),
                borderRadius: BorderRadius.circular(bodyRadius),
                border: Border.all(color: _rimColor, width: 1),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                  if (highlighted)
                    const BoxShadow(
                      color: Color(0x66E8602C),
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
                      child: ColoredBox(color: Colors.white, child: child),
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
