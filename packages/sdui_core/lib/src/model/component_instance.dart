import 'package:sdui_core/src/model/sdui_node.dart';

/// Nó que usa um componente por referência, na forma
/// `{"id", "type": "component", "props": {"componentId", "args"}}`.
/// Fica fora do `widgetCatalog`, então a paleta nunca o oferece.
abstract final class ComponentInstance {
  static const type = 'component';
  static const componentIdKey = 'componentId';
  static const argsKey = 'args';

  static bool isInstance(SduiNode node) => node.type == type;

  static String? componentIdOf(SduiNode node) {
    final value = node.properties[componentIdKey];
    return value is String && value.isNotEmpty ? value : null;
  }

  static Map<String, dynamic> argsOf(SduiNode node) {
    final value = node.properties[argsKey];
    return value is Map ? value.cast<String, dynamic>() : const {};
  }
}
