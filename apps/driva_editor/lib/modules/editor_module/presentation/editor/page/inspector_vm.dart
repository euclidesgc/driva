import 'package:flutter/foundation.dart';
import 'package:sdui_core/sdui_core.dart';

@immutable
class InspectorVm {
  const InspectorVm({
    required this.node,
    required this.isRoot,
    required this.safeArea,
    required this.contentName,
    required this.contentSlug,
    required this.isReadOnly,
  });

  /// `null` = nenhum nó selecionado; o Inspector mostra a página.
  final SduiNode? node;

  final bool isRoot;
  final Map<String, dynamic> safeArea;
  final String contentName;
  final String contentSlug;

  /// Rascunho congelado pelo modo de comparação.
  final bool isReadOnly;

  @override
  bool operator ==(Object other) =>
      other is InspectorVm &&
      other.node == node &&
      other.isRoot == isRoot &&
      mapEquals(other.safeArea, safeArea) &&
      other.contentName == contentName &&
      other.contentSlug == contentSlug &&
      other.isReadOnly == isReadOnly;

  @override
  int get hashCode => Object.hash(
    node,
    isRoot,
    Object.hashAllUnordered([
      for (final entry in safeArea.entries) Object.hash(entry.key, entry.value),
    ]),
    contentName,
    contentSlug,
    isReadOnly,
  );
}
