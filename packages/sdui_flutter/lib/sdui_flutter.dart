/// Renderer SDUI do driva: desenha um ContentSpec/SduiNode do `sdui_core` como
/// widgets Flutter via registry `type → builder`. Usado pelo preview do
/// editor e, futuramente, pelos apps dos clientes.
///
/// [DrivaContent] é a fachada pública reservada para os apps clientes: por ora
/// só o nome e o contrato de dados (`slug`). A resolução por slug em runtime e o
/// `Driva.init(projectId:)` chegam no próximo incremento — ainda não estão aqui.
library;

export 'src/builders/default_registry.dart';
export 'src/driva_content.dart';
export 'src/parsing/material_icons.dart' show curatedIconNames;
export 'src/registry.dart';
export 'src/renderer.dart';
export 'src/sdui_view.dart';
