/// Estilo do recorte da câmera desenhado sobre o topo da tela na moldura.
enum DeviceNotch {
  /// Ilha central (pill) — smartphones modernos.
  pill,

  /// Furo pequeno de câmera, canto superior — telas quase cheias e tablets.
  punchHole,
}

/// Molduras de dispositivo do preview (requisito: ≥ 3 presets).
///
/// Além das dimensões da tela, cada preset descreve a espessura do bezel, o
/// raio dos cantos e o tipo de recorte da câmera — dados que a moldura realista
/// (`_DeviceFrame` em `canvas_panel.dart`) usa para se aproximar do device real.
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
  );

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

  /// Espessura do bezel (borda preta ao redor da tela), em pixels lógicos.
  final double bezel;

  /// Raio dos cantos da tela.
  final double cornerRadius;

  /// Estilo do recorte da câmera desenhado sobre o topo da tela.
  final DeviceNotch notch;
}
