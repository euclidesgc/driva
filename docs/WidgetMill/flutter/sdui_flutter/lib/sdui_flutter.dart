/// Renderer do WidgetMill: constrói widgets Flutter a partir do spec JSON.
library sdui_flutter;

export 'src/actions/sdui_action.dart' show SduiAction, SduiActionHandler;
export 'src/binding/resolve_bindings.dart' show resolveBindings;
export 'src/model/sdui_node.dart';
export 'src/renderer.dart' show SduiRenderer, SduiRegistry, SduiBuilder;
export 'src/builders/default_registry.dart'
    show buildDefaultRegistry, defaultRegistry;
export 'src/sdui_view.dart';
