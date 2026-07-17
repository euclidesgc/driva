import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:equatable/equatable.dart';

/// A API devolve a lista **flat**; montar a árvore por `parentId` é
/// derivação da presentation (decisão registrada no contrato do
/// repositório) — é isso que [CategoryNode.buildForest] faz.
class CategoryNode extends Equatable {
  const CategoryNode({required this.category, required this.children});

  final Category category;
  final List<CategoryNode> children;

  String get id => category.id;
  String get name => category.name;

  @override
  List<Object?> get props => [category, children];

  /// Monta a floresta de nós de topo (sem `parentId`, ou cujo pai não existe
  /// mais na lista — órfão vira raiz em vez de sumir da árvore) a partir da
  /// lista flat [categories]. Cada nível é ordenado por nome.
  static List<CategoryNode> buildForest(List<Category> categories) {
    final byId = {for (final c in categories) c.id: c};
    final childrenOf = <String?, List<Category>>{};
    for (final category in categories) {
      final parentId =
          category.parentId != null && byId.containsKey(category.parentId)
          ? category.parentId
          : null;
      (childrenOf[parentId] ??= []).add(category);
    }

    CategoryNode build(Category category) {
      final children = (childrenOf[category.id] ?? const <Category>[]).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return CategoryNode(
        category: category,
        children: children.map(build).toList(),
      );
    }

    final roots = (childrenOf[null] ?? const <Category>[]).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return roots.map(build).toList();
  }

  /// Achata a árvore em pré-ordem, junto com a profundidade de cada nó (0 =
  /// raiz) — o que a lista da UI precisa para indentar e mostrar/ocultar
  /// subárvores recolhidas.
  static List<(CategoryNode node, int depth)> flatten(
    List<CategoryNode> forest, {
    Set<String> collapsedIds = const {},
    int depth = 0,
  }) {
    final result = <(CategoryNode, int)>[];
    for (final node in forest) {
      result.add((node, depth));
      if (node.children.isNotEmpty && !collapsedIds.contains(node.id)) {
        result.addAll(
          flatten(node.children, collapsedIds: collapsedIds, depth: depth + 1),
        );
      }
    }
    return result;
  }
}
