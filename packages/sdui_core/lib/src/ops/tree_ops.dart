/// Operações puras sobre a árvore do spec. Toda função devolve uma **nova**
/// raiz (imutabilidade) — é o que permite ao editor implementar undo/redo no
/// futuro como uma pilha de specs.
library;

import '../model/sdui_node.dart';

/// Busca um nó por [id] (a própria raiz inclusive). `null` se não existe.
SduiNode? findNode(SduiNode root, String id) {
  if (root.id == id) return root;
  if (root.child != null) {
    final found = findNode(root.child!, id);
    if (found != null) return found;
  }
  for (final child in root.children) {
    final found = findNode(child, id);
    if (found != null) return found;
  }
  return null;
}

/// Pai do nó [id]. `null` se [id] é a raiz ou não existe.
SduiNode? findParent(SduiNode root, String id) {
  if (root.child?.id == id) return root;
  for (final child in root.children) {
    if (child.id == id) return root;
  }
  if (root.child != null) {
    final found = findParent(root.child!, id);
    if (found != null) return found;
  }
  for (final child in root.children) {
    final found = findParent(child, id);
    if (found != null) return found;
  }
  return null;
}

/// Insere [node] em `children` de [parentId], na posição [index]
/// (clampada ao tamanho da lista). Sem efeito se [parentId] não existe.
SduiNode insertChild(
  SduiNode root,
  String parentId,
  int index,
  SduiNode node,
) {
  return _rebuild(root, (current) {
    if (current.id != parentId) return current;
    final children = [...current.children];
    children.insert(index.clamp(0, children.length), node);
    return current.copyWith(children: children);
  });
}

/// Define o `child` (slot único) de [parentId], substituindo o existente.
SduiNode setChild(SduiNode root, String parentId, SduiNode? node) {
  return _rebuild(root, (current) {
    if (current.id != parentId) return current;
    return current.copyWith(child: () => node);
  });
}

/// Remove o nó [id] de onde estiver (slot único ou lista). Remover a raiz
/// não tem efeito.
SduiNode removeNode(SduiNode root, String id) {
  return _rebuild(root, (current) {
    var next = current;
    if (next.child?.id == id) {
      next = next.copyWith(child: () => null);
    }
    if (next.children.any((c) => c.id == id)) {
      next = next.copyWith(
        children: [
          for (final c in next.children)
            if (c.id != id) c,
        ],
      );
    }
    return next;
  });
}

/// Move o nó [id] para `children` de [newParentId] na posição [index].
///
/// Sem efeito se: o nó ou o destino não existem, o destino está dentro da
/// própria subárvore do nó (criaria ciclo), ou o nó é a raiz.
SduiNode moveNode(SduiNode root, String id, String newParentId, int index) {
  if (id == root.id) return root;
  final node = findNode(root, id);
  if (node == null) return root;
  if (findNode(node, newParentId) != null) return root;
  if (findNode(root, newParentId) == null) return root;

  // Mover para o mesmo pai: o índice se refere à lista SEM o nó, então
  // remover primeiro e inserir depois já produz a posição certa.
  final without = removeNode(root, id);
  return insertChild(without, newParentId, index, node);
}

/// Aplica [patch] nas props do nó [id] (merge). Valor `null` no patch
/// **remove** a chave (volta ao default do renderer).
SduiNode updateNodeProps(
  SduiNode root,
  String id,
  Map<String, dynamic> patch,
) {
  return _rebuild(root, (current) {
    if (current.id != id) return current;
    final merged = {...current.properties, ...patch}
      ..removeWhere((_, value) => value == null);
    return current.copyWith(properties: merged);
  });
}

/// Reconstrói a árvore de baixo para cima aplicando [transform] a cada nó.
SduiNode _rebuild(SduiNode node, SduiNode Function(SduiNode) transform) {
  var next = node;
  if (next.child != null) {
    final child = _rebuild(next.child!, transform);
    if (!identical(child, next.child)) {
      next = next.copyWith(child: () => child);
    }
  }
  if (next.children.isNotEmpty) {
    final children = [
      for (final c in next.children) _rebuild(c, transform),
    ];
    next = next.copyWith(children: children);
  }
  return transform(next);
}
