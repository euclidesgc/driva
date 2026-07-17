import 'package:flutter/foundation.dart';
import 'package:sdui_core/sdui_core.dart';

@immutable
class InspectorVm {
  const InspectorVm({
    required this.node,
    required this.isContent,
    required this.contentName,
    required this.contentSlug,
  });

  final SduiNode? node;
  final bool isContent;
  final String contentName;
  final String contentSlug;

  @override
  bool operator ==(Object other) =>
      other is InspectorVm &&
      other.node == node &&
      other.isContent == isContent &&
      other.contentName == contentName &&
      other.contentSlug == contentSlug;

  @override
  int get hashCode => Object.hash(node, isContent, contentName, contentSlug);
}
