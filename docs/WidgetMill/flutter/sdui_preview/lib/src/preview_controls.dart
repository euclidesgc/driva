import 'package:device_frame_plus/device_frame_plus.dart';
import 'package:flutter/material.dart';

import 'device_catalog.dart';

/// Barra de controles do preview. Vive **fora** da tela simulada (usa o
/// `MediaQuery` real da janela), oferecendo: seletor de dispositivo, rotação,
/// claro/escuro, escala de texto e moldura on/off.
class PreviewControls extends StatelessWidget {
  const PreviewControls({
    super.key,
    required this.device,
    required this.orientation,
    required this.brightness,
    required this.showFrame,
    required this.safeArea,
    required this.textScale,
    required this.onDeviceChanged,
    required this.onToggleOrientation,
    required this.onBrightnessChanged,
    required this.onShowFrameChanged,
    required this.onSafeAreaChanged,
    required this.onTextScaleChanged,
  });

  final DeviceInfo device;
  final Orientation orientation;
  final Brightness brightness;
  final bool showFrame;
  final bool safeArea;
  final double textScale;

  final ValueChanged<DeviceInfo> onDeviceChanged;
  final VoidCallback onToggleOrientation;
  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<bool> onShowFrameChanged;
  final ValueChanged<bool> onSafeAreaChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final canRotate = device.canRotate;

    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _deviceDropdown(),
            IconButton(
              tooltip: canRotate
                  ? 'Girar (${orientation == Orientation.portrait ? 'retrato' : 'paisagem'})'
                  : 'Este dispositivo não rotaciona',
              onPressed: canRotate ? onToggleOrientation : null,
              isSelected: orientation == Orientation.landscape,
              icon: const Icon(Icons.screen_rotation),
            ),
            IconButton(
              tooltip: isDark ? 'Tema: escuro' : 'Tema: claro',
              onPressed: () => onBrightnessChanged(
                isDark ? Brightness.light : Brightness.dark,
              ),
              isSelected: isDark,
              icon: const Icon(Icons.light_mode),
              selectedIcon: const Icon(Icons.dark_mode),
            ),
            IconButton(
              tooltip: showFrame ? 'Moldura: ligada' : 'Moldura: desligada',
              onPressed: () => onShowFrameChanged(!showFrame),
              isSelected: showFrame,
              icon: const Icon(Icons.crop_din),
              selectedIcon: const Icon(Icons.smartphone),
            ),
            IconButton(
              tooltip: safeArea
                  ? 'Safe area: respeitando o notch'
                  : 'Safe area: edge-to-edge',
              onPressed: () => onSafeAreaChanged(!safeArea),
              isSelected: safeArea,
              icon: const Icon(Icons.fit_screen),
              selectedIcon: const Icon(Icons.padding),
            ),
            _textScaleControl(),
          ],
        ),
      ),
    );
  }

  Widget _deviceDropdown() {
    return DropdownButton<DeviceInfo>(
      value: device,
      underline: const SizedBox.shrink(),
      items: [
        for (final d in DeviceCatalog.all)
          DropdownMenuItem<DeviceInfo>(
            value: d,
            child: Text(_deviceLabel(d)),
          ),
      ],
      onChanged: (d) {
        if (d != null) onDeviceChanged(d);
      },
    );
  }

  Widget _textScaleControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.format_size, size: 18),
        SizedBox(
          width: 120,
          child: Slider(
            min: 0.8,
            max: 2.0,
            divisions: 12,
            value: textScale.clamp(0.8, 2.0),
            label: '${textScale.toStringAsFixed(1)}×',
            onChanged: onTextScaleChanged,
          ),
        ),
        Text('${textScale.toStringAsFixed(1)}×'),
      ],
    );
  }

  /// Rótulo "Nome · LxA" (tamanho lógico em retrato).
  String _deviceLabel(DeviceInfo d) {
    final s = d.screenSize;
    return '${d.name} · ${s.width.toInt()}×${s.height.toInt()}';
  }
}
