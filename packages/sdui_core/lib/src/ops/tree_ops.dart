import 'package:sdui_core/src/catalog/widget_catalog.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/sdui_node.dart';

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

SduiNode insertChild(SduiNode root, String parentId, int index, SduiNode node) {
  return _rebuild(root, (current) {
    if (current.id != parentId) return current;
    final children = [...current.children];
    children.insert(index.clamp(0, children.length), node);
    return current.copyWith(children: children);
  });
}

SduiNode setChild(SduiNode root, String parentId, SduiNode? node) {
  return _rebuild(root, (current) {
    if (current.id != parentId) return current;
    return current.copyWith(child: () => node);
  });
}

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

SduiNode moveNode(SduiNode root, String id, String newParentId, int index) {
  if (id == root.id) return root;
  final node = findNode(root, id);
  if (node == null) return root;
  if (findNode(node, newParentId) != null) return root;
  if (findNode(root, newParentId) == null) return root;

  // Mover para o mesmo pai: o índice se refere à lista SEM o nó, então
  // remover primeiro e inserir depois já produz a posição certa.
  final without = removeNode(root, id);
  return attachNode(without, newParentId, index, node) ?? root;
}

/// O slot do destino decide o campo: `children` (multi) ou `child` (single).
/// Escrever na lista de um slot único produz um documento que o renderer não
/// desenha e que `parseContentSpec` recusa no reload — por isso a guarda mora
/// aqui, e não no chamador. `null` = destino não aceita o nó.
SduiNode? attachNode(SduiNode root, String parentId, int index, SduiNode node) {
  final parent = findNode(root, parentId);
  if (parent == null) return null;
  return switch (descriptorFor(parent.type)?.slot ?? SlotKind.none) {
    SlotKind.multi => insertChild(root, parentId, index, node),
    SlotKind.single when parent.child == null => setChild(root, parentId, node),
    _ => null,
  };
}

SduiNode updateNodeProps(SduiNode root, String id, Map<String, dynamic> patch) {
  return _rebuild(root, (current) {
    if (current.id != id) return current;
    final merged = {...current.properties, ...patch}
      ..removeWhere((_, value) => value == null);
    return current.copyWith(properties: merged);
  });
}

SduiNode _rebuild(SduiNode node, SduiNode Function(SduiNode) transform) {
  var next = node;
  if (next.child != null) {
    final child = _rebuild(next.child!, transform);
    if (!identical(child, next.child)) {
      next = next.copyWith(child: () => child);
    }
  }
  if (next.children.isNotEmpty) {
    final children = [for (final c in next.children) _rebuild(c, transform)];
    next = next.copyWith(children: children);
  }
  return transform(next);
}
