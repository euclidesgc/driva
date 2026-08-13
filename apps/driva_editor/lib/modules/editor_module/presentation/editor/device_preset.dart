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
    safeAreaTop: 59,
    safeAreaBottom: 34,
  ),
  android(
    'Android',
    412,
    915,
    bezel: 12,
    cornerRadius: 38,
    notch: DeviceNotch.punchHole,
    safeAreaTop: 28,
    safeAreaBottom: 24,
  ),
  tablet(
    'Tablet',
    820,
    1180,
    bezel: 22,
    cornerRadius: 30,
    notch: DeviceNotch.punchHole,
    safeAreaTop: 24,
    safeAreaBottom: 20,
  ),
  ;

  const DevicePreset(
    this.label,
    this.width,
    this.height, {
    required this.bezel,
    required this.cornerRadius,
    required this.notch,
    required this.safeAreaTop,
    required this.safeAreaBottom,
  });

  final String label;
  final double width;
  final double height;
  final double bezel;
  final double cornerRadius;
  final DeviceNotch notch;

  /// Medidas do aparelho, não do tema: o que o sistema reserva no topo (notch,
  /// barra de status) e na base (barra de gestos).
  final double safeAreaTop;
  final double safeAreaBottom;

  /// Sem injetar isto no `MediaQuery` do mock, o `SafeArea` da página herdaria
  /// o recuo do navegador e o preview mentiria.
  EdgeInsets get safeAreaPadding =>
      EdgeInsets.only(top: safeAreaTop, bottom: safeAreaBottom);
}
