enum DeviceNotch { pill, punchHole }

enum DevicePreset {
  smartphone(
    'Smartphone',
    393,
    852,
    bezel: 14,
    cornerRadius: 46,
    notch: DeviceNotch.pill,
  ),
  android(
    'Android',
    412,
    915,
    bezel: 12,
    cornerRadius: 38,
    notch: DeviceNotch.punchHole,
  ),
  tablet(
    'Tablet',
    820,
    1180,
    bezel: 22,
    cornerRadius: 30,
    notch: DeviceNotch.punchHole,
  )
  ;

  const DevicePreset(
    this.label,
    this.width,
    this.height, {
    required this.bezel,
    required this.cornerRadius,
    required this.notch,
  });

  final String label;
  final double width;
  final double height;
  final double bezel;
  final double cornerRadius;
  final DeviceNotch notch;
}
