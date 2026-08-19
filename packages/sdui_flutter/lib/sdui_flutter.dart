/// Renderer SDUI do driva: desenha um ContentSpec/SduiNode do `sdui_core` como
/// widgets Flutter via registry `type → builder`. Usado pelo preview do
/// editor e pelo runtime que os apps dos clientes consomem.
///
/// A resolução por slug em runtime mora em `package:driva_client` — este
/// pacote é dependência dele, não o contrário.
library;

export 'src/builders/default_registry.dart';
export 'src/layout/sdui_safe_area.dart';
export 'src/parsing/material_icons.dart' show curatedIconNames;
export 'src/registry.dart';
export 'src/renderer.dart';
export 'src/sdui_view.dart';
