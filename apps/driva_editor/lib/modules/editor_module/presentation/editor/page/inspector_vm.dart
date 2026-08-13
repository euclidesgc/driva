import 'package:flutter/foundation.dart';
import 'package:sdui_core/sdui_core.dart';

@immutable
class InspectorVm {
  const InspectorVm({
    required this.node,
    required this.safeArea,
    required this.contentName,
    required this.contentSlug,
  });

  /// `null` = nenhum nó selecionado; o Inspector mostra a página.
  final SduiNode? node;

  final Map<String, dynamic> safeArea;
  final String contentName;
  final String contentSlug;

  @override
  bool operator ==(Object other) =>
      other is InspectorVm &&
      other.node == node &&
      mapEquals(other.safeArea, safeArea) &&
      other.contentName == contentName &&
      other.contentSlug == contentSlug;

  @override
  int get hashCode => Object.hash(
    node,
    Object.hashAllUnordered([
      for (final entry in safeArea.entries) Object.hash(entry.key, entry.value),
    ]),
    contentName,
    contentSlug,
  );
}
