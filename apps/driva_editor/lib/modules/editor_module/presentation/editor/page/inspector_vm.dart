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
    this.multiNodes = const [],
  });

  /// `null` = nenhum nó selecionado; o Inspector mostra a página.
  final SduiNode? node;

  final bool isRoot;
  final Map<String, dynamic> safeArea;
  final String contentName;
  final String contentSlug;

  /// Rascunho congelado pelo modo de comparação.
  final bool isReadOnly;

  /// Dois ou mais nós selecionados (edição em lote); vazio = seleção única.
  final List<SduiNode> multiNodes;

  @override
  bool operator ==(Object other) =>
      other is InspectorVm &&
      other.node == node &&
      other.isRoot == isRoot &&
      mapEquals(other.safeArea, safeArea) &&
      other.contentName == contentName &&
      other.contentSlug == contentSlug &&
      other.isReadOnly == isReadOnly &&
      listEquals(other.multiNodes, multiNodes);

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
    Object.hashAll(multiNodes),
  );
}
