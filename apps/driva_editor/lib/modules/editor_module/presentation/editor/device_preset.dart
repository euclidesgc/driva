/// Molduras de dispositivo do preview (requisito: ≥ 3 presets).
enum DevicePreset {
  smartphone('Smartphone', 393, 852),
  android('Android', 412, 915),
  tablet('Tablet', 820, 1180);

  const DevicePreset(this.label, this.width, this.height);

  final String label;
  final double width;
  final double height;
}
