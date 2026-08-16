import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/camera_cutout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_home_indicator.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/device_status_bar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/side_button.dart';
import 'package:flutter/material.dart';

class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    required this.device,
    required this.highlighted,
    required this.child,
    super.key,
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
    final frameSize = device.frameSize;

    return Semantics(
      label:
          'Moldura ${device.label} (${device.width.toInt()}'
          '×${device.height.toInt()})',
      child: SizedBox(
        width: frameSize.width,
        height: frameSize.height,
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
                border: Border.all(color: mock.rim),
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
                  // A status bar e o indicador de home entram **dentro** deste
                  // ClipRRect (não como irmãos do conteúdo): ambos desenham
                  // até a borda do aparelho, e fora do clip vazariam
                  // retangulares por cima das quinas arredondadas da tela.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(device.cornerRadius),
                    child: SizedBox(
                      width: device.width,
                      height: device.height,
                      child: Stack(
                        children: [
                          // `Positioned.fill`, não filho solto do Stack: um
                          // filho não-posicionado recebe constraints
                          // afrouxadas (`loosen()`) e o conteúdo encolheria
                          // para o próprio tamanho intrínseco, deixando o
                          // corpo escuro do aparelho aparecer por trás.
                          Positioned.fill(
                            child: ColoredBox(
                              color: mock.screen,
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  size: Size(device.width, device.height),
                                  padding: device.safeAreaPadding,
                                  viewPadding: device.safeAreaPadding,
                                  viewInsets: EdgeInsets.zero,
                                ),
                                child: child,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: DeviceStatusBar(device: device),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CameraCutout(notch: device.notch),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: DeviceHomeIndicator(device: device),
                            ),
                          ),
                        ],
                      ),
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
