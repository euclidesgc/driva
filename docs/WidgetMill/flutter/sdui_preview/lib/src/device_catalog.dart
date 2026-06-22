import 'package:device_frame_plus/device_frame_plus.dart';
import 'package:flutter/material.dart';

/// Catálogo de dispositivos do preview.
///
/// Reutiliza o `DeviceInfo` do `device_frame_plus` como modelo — ele já carrega
/// o tamanho lógico (`screenSize`), a densidade (`pixelRatio`), as safe areas
/// (`safeAreas`/`rotatedSafeAreas`) e a geometria da moldura. É a **fonte única**
/// dos dois caminhos de render (com moldura via `DeviceFrame`; sem moldura via
/// injeção manual de `MediaQuery`).
///
/// As entradas são `static final` e reaproveitadas por identidade: cada acesso a
/// `Devices.ios.iPhone13` cria uma nova instância (com um `framePainter`
/// diferente, logo `!=`), o que quebraria o casamento de valor do `Dropdown`.
/// Por isso cada dispositivo é instanciado **uma vez** aqui e referenciado
/// sempre a partir desta lista.
class DeviceCatalog {
  const DeviceCatalog._();

  /// Android compacto.
  static final DeviceInfo androidSmall = Devices.android.samsungGalaxyS20;

  /// Android grande (phablet).
  static final DeviceInfo androidLarge =
      Devices.android.samsungGalaxyNote20Ultra;

  /// iPhone.
  static final DeviceInfo iphone = Devices.ios.iPhone13;

  /// Tablet.
  static final DeviceInfo tablet = Devices.ios.iPad;

  /// Web/Desktop: tela grande, densidade 1.0 e sem safe area. Não rotaciona
  /// (`rotatedSafeAreas` ausente → `canRotate == false`). Usamos
  /// `windowPosition` = tela inteira para que o `screenSize` efetivo (que vira o
  /// `MediaQuery.size`) seja exatamente 1280×800.
  static final DeviceInfo webDesktop = DeviceInfo.genericDesktopMonitor(
    platform: TargetPlatform.linux,
    id: 'web-desktop-1280x800',
    name: 'Web / Desktop',
    screenSize: const Size(1280, 800),
    windowPosition: const Rect.fromLTWH(0, 0, 1280, 800),
    pixelRatio: 1.0,
  );

  /// Lista exibida no seletor (ordem estável).
  static final List<DeviceInfo> all = <DeviceInfo>[
    androidSmall,
    androidLarge,
    iphone,
    tablet,
    webDesktop,
  ];

  /// Dispositivo inicial (referência idêntica a um item de [all]).
  static final DeviceInfo defaultDevice = iphone;
}
