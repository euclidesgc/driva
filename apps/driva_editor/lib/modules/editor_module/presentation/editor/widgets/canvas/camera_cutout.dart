import 'package:flutter/material.dart';

import '../../device_preset.dart';

/// Recorte da câmera sobre a tela: pill central ou furo pequeno (punch-hole).
class CameraCutout extends StatelessWidget {
  const CameraCutout({super.key, required this.notch});

  final DeviceNotch notch;

  static const _color = Color(0xFF0B0C0E);

  @override
  Widget build(BuildContext context) {
    return switch (notch) {
      DeviceNotch.pill => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 90,
            height: 26,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      DeviceNotch.punchHole => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    };
  }
}
