import 'package:equatable/equatable.dart';

import 'package:sdui_core/src/catalog/widget_catalog.dart';
import 'package:sdui_core/src/catalog/widget_descriptor.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/ops/tree_ops.dart';

enum DropRefusal { unknownTarget, cycle, noSlotAvailable }

/// Onde um drop realmente encaixa, dado o alvo apontado pelo usuário.
///
/// Existe para que canvas e árvore compartilhem a mesma regra: apontar um nó
/// que não recebe filhos não cancela o gesto — o encaixe sobe para o primeiro
/// ancestral que recebe, e [DropAccepted.redirected] avisa que isso aconteceu.
sealed class DropResolution extends Equatable {
  const DropResolution();

  @override
  List<Object?> get props => [];
}

final class DropAccepted extends DropResolution {
  const DropAccepted({
    required this.parentId,
    required this.index,
    required this.redirected,
  });

  final String parentId;
  final int index;

  /// `true` quando o alvo apontado não recebia o nó e o encaixe subiu.
  final bool redirected;

  @override
  List<Object?> get props => [parentId, index, redirected];
}

final class DropRefused extends DropResolution {
  const DropRefused(this.refusal);

  final DropRefusal refusal;

  @override
  List<Object?> get props => [refusal];
}

/// [movingNodeId] null = nó novo vindo da paleta.
DropResolution resolveDrop(
  SduiNode root,
  String targetId, {
  String? movingNodeId,
}) {
  final target = findNode(root, targetId);
  if (target == null) return const DropRefused(DropRefusal.unknownTarget);

  if (movingNodeId != null) {
    final moving = findNode(root, movingNodeId);
    if (moving == null) return const DropRefused(DropRefusal.unknownTarget);
    if (findNode(moving, targetId) != null) {
      return const DropRefused(DropRefusal.cycle);
    }
  }

  if (_accepts(target, movingNodeId)) {
    return DropAccepted(
      parentId: target.id,
      index: _appendIndex(target),
      redirected: false,
    );
  }

  var rejected = target;
  while (true) {
    final parent = findParent(root, rejected.id);
    if (parent == null) return const DropRefused(DropRefusal.noSlotAvailable);
    if (_accepts(parent, movingNodeId)) {
      final position = parent.children.indexWhere((c) => c.id == rejected.id);
      return DropAccepted(
        parentId: parent.id,
        index: position >= 0 ? position + 1 : _appendIndex(parent),
        redirected: true,
      );
    }
    rejected = parent;
  }
}

/// Slot único já ocupado só recebe de volta o próprio ocupante — mover um nó
/// para o pai onde ele já está é legítimo (e vira no-op).
bool _accepts(SduiNode node, String? movingNodeId) {
  return switch (descriptorFor(node.type)?.slot ?? SlotKind.none) {
    SlotKind.multi => true,
    SlotKind.single =>
      node.child == null || node.child!.id == movingNodeId,
    SlotKind.none => false,
  };
}

int _appendIndex(SduiNode node) =>
    (descriptorFor(node.type)?.slot ?? SlotKind.none) == SlotKind.multi
    ? node.children.length
    : 0;
