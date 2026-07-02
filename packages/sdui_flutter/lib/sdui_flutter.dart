/// Renderer SDUI do driva: desenha um PageSpec/SduiNode do `sdui_core` como
/// widgets Flutter via registry `type → builder`. Usado pelo preview do
/// editor e, futuramente, pelos apps dos clientes.
library;

export 'src/builders/default_registry.dart';
export 'src/parsing/material_icons.dart' show curatedIconNames;
export 'src/registry.dart';
export 'src/renderer.dart';
export 'src/sdui_view.dart';
