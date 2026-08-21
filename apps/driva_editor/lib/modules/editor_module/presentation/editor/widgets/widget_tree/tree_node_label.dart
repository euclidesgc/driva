import 'package:sdui_core/sdui_core.dart';

String treeNodeLabel(SduiNode node, {bool isRoot = false}) {
  final descriptor = descriptorFor(node.type);
  final base = descriptor?.label ?? node.type;
  final text = node.properties['data'];
  if (node.type == 'text' && text is String && text.isNotEmpty) {
    return '$base — “$text”';
  }
  final buttonLabel = node.properties['label'];
  if (node.type == 'button' && buttonLabel is String) {
    return '$base — “$buttonLabel”';
  }
  return isRoot ? 'Conteúdo ($base)' : base;
}
