import 'package:device_frame_plus/device_frame_plus.dart';
import 'package:flutter/material.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

import 'src/bridge.dart';
import 'src/device_catalog.dart';
import 'src/device_preview.dart';
import 'src/incoming.dart';
import 'src/preview_controls.dart';
import 'src/preview_message.dart';

/// Origens permitidas, configuráveis na build:
/// `flutter build web --dart-define=PREVIEW_ALLOWED_ORIGINS=https://app.exemplo.com`.
/// Vazio (dev) = aceita qualquer origem.
const _allowedOriginsRaw = String.fromEnvironment("PREVIEW_ALLOWED_ORIGINS");

void main() => runApp(const PreviewApp());

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PreviewHost(),
      );
}

/// Hospeda o renderer e a bridge: recebe specs do editor e devolve eventos.
class PreviewHost extends StatefulWidget {
  const PreviewHost({super.key});

  @override
  State<PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends State<PreviewHost> {
  late final PreviewBridge _bridge;
  RenderSpec? _current;

  // Estado do preview (gerência via setState — padrão já usado no projeto).
  DeviceInfo _device = DeviceCatalog.defaultDevice;
  Orientation _orientation = Orientation.portrait;
  Brightness _brightness = Brightness.light;
  bool _showFrame = true;
  bool _safeArea = true;
  double _textScale = 1.0;

  // Diagnóstico: nº de mensagens recebidas do editor (visível no placeholder).
  int _inbound = 0;

  @override
  void initState() {
    super.initState();
    _bridge = PreviewBridge(
      allowedOrigins: parseAllowedOrigins(_allowedOriginsRaw),
      onRender: (render) => setState(() => _current = render),
      onInbound: () {
        if (mounted) setState(() => _inbound++);
      },
    );
    _bridge.start();
  }

  void _selectDevice(DeviceInfo device) {
    setState(() {
      _device = device;
      // Dispositivos que não rotacionam voltam para retrato.
      if (!device.canRotate) _orientation = Orientation.portrait;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    // Sem spec (ex.: app standalone), mostramos um demo que imprime os valores
    // do MediaQuery simulado — útil para validar a feature sem o editor.
    final Widget child = current == null
        ? _PreviewPlaceholder(inbound: _inbound)
        : SduiView.fromJson(
            current.spec,
            data: current.data,
            tokens: current.tokens,
            onAction: (action) =>
                _bridge.post(PreviewEvents.tap(action.type, action.params)),
          );

    final stage = DevicePreview(
      device: _device,
      orientation: _orientation,
      brightness: _brightness,
      showFrame: _showFrame,
      safeArea: _safeArea,
      textScaleFactor: _textScale,
      child: child,
    );

    return Scaffold(
      body: Column(
        children: [
          PreviewControls(
            device: _device,
            orientation: _orientation,
            brightness: _brightness,
            showFrame: _showFrame,
            safeArea: _safeArea,
            textScale: _textScale,
            onDeviceChanged: _selectDevice,
            onToggleOrientation: () => setState(() {
              _orientation = _orientation == Orientation.portrait
                  ? Orientation.landscape
                  : Orientation.portrait;
            }),
            onBrightnessChanged: (b) => setState(() => _brightness = b),
            onShowFrameChanged: (v) => setState(() => _showFrame = v),
            onSafeAreaChanged: (v) => setState(() => _safeArea = v),
            onTextScaleChanged: (v) => setState(() => _textScale = v),
          ),
          Expanded(
            // Palco neutro atrás da "tela" simulada.
            child: ColoredBox(
              color: const Color(0xFFE9ECEF),
              child: stage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo exibido quando ainda não chegou nenhum spec do editor. Lê e imprime os
/// valores do `MediaQuery` mais próximo — que aqui é o **simulado**. Serve de
/// prova viva dos critérios de aceite: trocar de aparelho muda `size`/`padding`/
/// `devicePixelRatio`; girar inverte o `size`; alternar o brilho muda o tema.
class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.inbound});

  /// Diagnóstico: nº de mensagens recebidas do editor. Se permanecer 0, o
  /// editor não está conseguindo enviar (problema no lado React/handshake).
  final int inbound;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Text(label, style: theme.textTheme.labelMedium),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Preview', style: theme.textTheme.titleLarge),
              Text(
                'Valores lidos do MediaQuery (simulado):',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              row('size',
                  '${mq.size.width.toStringAsFixed(1)} × ${mq.size.height.toStringAsFixed(1)}'),
              row('devicePixelRatio', mq.devicePixelRatio.toStringAsFixed(2)),
              row('padding (safe area)', mq.padding.toString()),
              row('platformBrightness', mq.platformBrightness.name),
              row('textScale (de ×1)', mq.textScaler.scale(1).toStringAsFixed(2)),
              const SizedBox(height: 16),
              Text(
                'aguardando spec do editor… (mensagens recebidas: $inbound)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.disabledColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
