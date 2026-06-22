import 'package:device_frame_plus/device_frame_plus.dart';
import 'package:flutter/material.dart';

/// Simula um dispositivo "mentindo" para o widget sobre o ambiente via
/// `MediaQuery`. Nenhuma emulação real — todo widget que se adapta à tela lê
/// tamanho/safe area/densidade/brilho/escala de texto do `MediaQuery` mais
/// próximo; injetando um artificial, o widget obedece sem saber que é falso.
///
/// Dois caminhos, atrás de [showFrame]:
/// - `true`  → [DeviceFrame] pinta a moldura física **e** injeta o `MediaQuery`
///   simulado (tamanho, densidade, safe areas, plataforma), além de já escalar
///   via `FittedBox`. Não duplicamos a injeção: apenas sobrepomos brilho e
///   escala de texto no `MediaQuery` ambiente, que o `DeviceFrame` preserva
///   (ele faz `copyWith` sobre o herdado, sobrescrevendo só a geometria).
/// - `false` → injeção manual leve do `MediaQuery` + `SizedBox` no tamanho
///   lógico + `FittedBox` para caber no painel.
///
/// Em ambos, o widget visualizado fica sob um `MaterialApp` interno isolado
/// ([_SimulatedScreen]). No Flutter 3.38 `useInheritedMediaQuery` foi depreciado
/// e é ignorado: o `WidgetsApp` **nunca** cria o próprio `MediaQuery`, sempre
/// herda o ancestral — logo o app interno usa o `MediaQuery` simulado por padrão.
class DevicePreview extends StatelessWidget {
  const DevicePreview({
    super.key,
    required this.device,
    required this.orientation,
    required this.brightness,
    required this.child,
    this.showFrame = true,
    this.textScaleFactor = 1.0,
    this.safeArea = true,
  });

  /// Dispositivo simulado (modelo do `device_frame_plus`).
  final DeviceInfo device;

  /// Orientação simulada. Ignorada se o dispositivo não rotaciona
  /// (`device.canRotate == false`, ex.: web/desktop).
  final Orientation orientation;

  /// Brilho da plataforma simulado (claro/escuro).
  final Brightness brightness;

  /// Se `true`, desenha a moldura física do aparelho.
  final bool showFrame;

  /// Escala de texto (acessibilidade). 1.0 = padrão.
  final double textScaleFactor;

  /// Se `true`, envolve o widget num [SafeArea] — o conteúdo respeita o notch e
  /// as safe areas do aparelho (fidelidade). Desligue para inspecionar
  /// edge-to-edge. Padrão `true`.
  final bool safeArea;

  /// Widget a visualizar dentro da "tela" do dispositivo.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = _SimulatedScreen(
      brightness: brightness,
      safeArea: safeArea,
      child: child,
    );

    if (showFrame) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MediaQuery(
            // Brilho e escala de texto não são simulados pelo DeviceFrame; ele
            // os preserva do MediaQuery ambiente. A geometria (tamanho, padding,
            // densidade, plataforma) o DeviceFrame sobrescreve sozinho.
            data: MediaQuery.of(context).copyWith(
              platformBrightness: brightness,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: DeviceFrame(
              device: device,
              orientation: orientation,
              screen: screen,
            ),
          ),
        ),
      );
    }

    // Caminho leve (sem moldura): injeção manual do MediaQuery.
    final isLandscape = device.isLandscape(orientation);
    final size = isLandscape
        ? Size(device.screenSize.height, device.screenSize.width)
        : device.screenSize;
    final safeAreaInsets = isLandscape
        ? (device.rotatedSafeAreas ?? _rotateInsets(device.safeAreas))
        : device.safeAreas;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                devicePixelRatio: device.pixelRatio,
                padding: safeAreaInsets,
                viewPadding: safeAreaInsets,
                platformBrightness: brightness,
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: screen,
            ),
          ),
        ),
      ),
    );
  }

  /// Gira insets ao inverter para landscape (fallback quando o dispositivo não
  /// fornece `rotatedSafeAreas`). O que era topo/baixo vira lateral.
  EdgeInsets _rotateInsets(EdgeInsets i) =>
      EdgeInsets.fromLTRB(i.top, i.right, i.bottom, i.left);
}

/// `MaterialApp` interno isolado: o brilho simulado dirige o tema do widget
/// (light/dark) e o app herda automaticamente o `MediaQuery` simulado de cima.
class _SimulatedScreen extends StatelessWidget {
  const _SimulatedScreen({
    required this.brightness,
    required this.safeArea,
    required this.child,
  });

  final Brightness brightness;
  final bool safeArea;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // O SafeArea fica DENTRO do MaterialApp para ler o MediaQuery simulado
    // (cujo `padding` = safe areas do aparelho injetadas por cima). Assim o
    // notch não invade o widget construído.
    final body = safeArea ? SafeArea(child: child) : child;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: body),
    );
  }
}
