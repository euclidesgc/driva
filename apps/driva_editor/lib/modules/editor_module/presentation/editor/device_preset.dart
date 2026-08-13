import 'package:flutter/widgets.dart';

enum DeviceNotch { pill, punchHole }

enum DevicePreset {
  smartphone(
    'Smartphone',
    393,
    852,
    bezel: 14,
    cornerRadius: 46,
    notch: DeviceNotch.pill,
    safeAreaPadding: EdgeInsets.only(top: 59, bottom: 34),
  ),
  android(
    'Android',
    412,
    915,
    bezel: 12,
    cornerRadius: 38,
    notch: DeviceNotch.punchHole,
    safeAreaPadding: EdgeInsets.only(top: 28, bottom: 24),
  ),
  tablet(
    'Tablet',
    820,
    1180,
    bezel: 22,
    cornerRadius: 30,
    notch: DeviceNotch.punchHole,
    safeAreaPadding: EdgeInsets.only(top: 24, bottom: 20),
  ),
  ;

  const DevicePreset(
    this.label,
    this.width,
    this.height, {
    required this.bezel,
    required this.cornerRadius,
    required this.notch,
    required this.safeAreaPadding,
  });

  final String label;
  final double width;
  final double height;
  final double bezel;
  final double cornerRadius;
  final DeviceNotch notch;

  /// Recuo que o sistema reserva no dispositivo real (notch, barra de status,
  /// barra de gestos). Sem injetá-lo no `MediaQuery` do mock, o `SafeArea` da
  /// página herdaria o recuo do navegador e o preview mentiria.
  final EdgeInsets safeAreaPadding;
}
