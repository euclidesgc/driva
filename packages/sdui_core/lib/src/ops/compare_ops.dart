import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:sdui_core/src/model/content_spec.dart';
import 'package:sdui_core/src/model/sdui_node.dart';

/// A identidade de nó nesta v1 é o `id`: componentes, ações e binding
/// (`{{prop}}`) referenciam nó por `id`, nunca por posição. Um `id` repetido
/// em qualquer árvore torna ambígua qualquer cópia — [compareContentSpecs] e
/// [copyComparableNodeProperties] recusam a operação inteira nesse caso, sem
/// resultado parcial e sem alterar nó algum.
sealed class ComparisonFailure extends Equatable {
  const ComparisonFailure();
}

final class DuplicateNodeIdComparisonFailure extends ComparisonFailure {
  const DuplicateNodeIdComparisonFailure({
    required this.baseDuplicateIds,
    required this.candidateDuplicateIds,
  });

  final Set<String> baseDuplicateIds;
  final Set<String> candidateDuplicateIds;

  @override
  List<Object?> get props => [baseDuplicateIds, candidateDuplicateIds];
}

final class NodeNotFoundForCopyFailure extends ComparisonFailure {
  const NodeNotFoundForCopyFailure(this.nodeId);

  final String nodeId;

  @override
  List<Object?> get props => [nodeId];
}

final class NodeTypeMismatchForCopyFailure extends ComparisonFailure {
  const NodeTypeMismatchForCopyFailure({
    required this.nodeId,
    required this.baseType,
    required this.candidateType,
  });

  final String nodeId;
  final String baseType;
  final String candidateType;

  @override
  List<Object?> get props => [nodeId, baseType, candidateType];
}

/// A candidata tem uma propriedade com chave fora do contrato JSON do spec
/// (`Map` com chave que não é `String`, só possível vindo de um documento
/// montado em memória, nunca de `parseContentSpec`) — copiar exigiria
/// inventar uma chave, então a v1 recusa em vez de arriscar.
final class NonStringPropertyKeyForCopyFailure extends ComparisonFailure {
  const NonStringPropertyKeyForCopyFailure(this.nodeId);

  final String nodeId;

  @override
  List<Object?> get props => [nodeId];
}

class NodeDiff extends Equatable {
  const NodeDiff({
    required this.nodeId,
    required this.baseType,
    required this.candidateType,
    required this.propertiesChanged,
    required this.eventsChanged,
    required this.childOrderChanged,
    required this.baseParentId,
    required this.candidateParentId,
  });

  final String nodeId;
  final String baseType;
  final String candidateType;
  final bool propertiesChanged;
  final bool eventsChanged;

  /// v1 só reporta: nenhuma operação deste módulo reordena filhos.
  final bool childOrderChanged;

  /// `null` quando o nó é a raiz do respectivo spec.
  final String? baseParentId;
  final String? candidateParentId;

  bool get typeChanged => baseType != candidateType;

  /// v1 só reporta: nenhuma operação deste módulo move um nó entre pais —
  /// mudar de pai é merge estrutural, fora do recorte (ver
  /// [ComparisonFailure]).
  bool get parentChanged => baseParentId != candidateParentId;

  bool get hasChanges =>
      typeChanged ||
      propertiesChanged ||
      eventsChanged ||
      childOrderChanged ||
      parentChanged;

  @override
  List<Object?> get props => [
    nodeId,
    baseType,
    candidateType,
    propertiesChanged,
    eventsChanged,
    childOrderChanged,
    baseParentId,
    candidateParentId,
  ];
}

class SpecComparisonResult extends Equatable {
  const SpecComparisonResult({
    required this.nodeDiffs,
    required this.nodesOnlyInBase,
    required this.nodesOnlyInCandidate,
    required this.safeAreaChanged,
    required this.changedContentMetadataFields,
  });

  final List<NodeDiff> nodeDiffs;
  final Set<String> nodesOnlyInBase;
  final Set<String> nodesOnlyInCandidate;
  final bool safeAreaChanged;
  final Set<String> changedContentMetadataFields;

  bool get hasDifferences =>
      nodeDiffs.any((diff) => diff.hasChanges) ||
      nodesOnlyInBase.isNotEmpty ||
      nodesOnlyInCandidate.isNotEmpty ||
      safeAreaChanged ||
      changedContentMetadataFields.isNotEmpty;

  @override
  List<Object?> get props => [
    nodeDiffs,
    nodesOnlyInBase,
    nodesOnlyInCandidate,
    safeAreaChanged,
    changedContentMetadataFields,
  ];
}

Either<ComparisonFailure, SpecComparisonResult> compareContentSpecs(
  ContentSpec base,
  ContentSpec candidate,
) {
  final baseIndex = _TreeIndex.of(base.root);
  final candidateIndex = _TreeIndex.of(candidate.root);

  final duplicateFailure = _duplicateFailure(baseIndex, candidateIndex);
  if (duplicateFailure != null) return Left(duplicateFailure);

  final sharedIds = baseIndex.byId.keys.toSet().intersection(
    candidateIndex.byId.keys.toSet(),
  );

  final nodeDiffs = [
    for (final id in sharedIds)
      _diffNode(
        baseIndex.byId[id]!,
        candidateIndex.byId[id]!,
        baseParentId: baseIndex.parentIdById[id],
        candidateParentId: candidateIndex.parentIdById[id],
      ),
  ]..sort((a, b) => a.nodeId.compareTo(b.nodeId));

  return Right(
    SpecComparisonResult(
      nodeDiffs: nodeDiffs,
      nodesOnlyInBase: baseIndex.byId.keys.toSet().difference(sharedIds),
      nodesOnlyInCandidate: candidateIndex.byId.keys.toSet().difference(
        sharedIds,
      ),
      safeAreaChanged: !_deepEquals(base.safeArea, candidate.safeArea),
      changedContentMetadataFields: _changedContentMetadataFields(
        base,
        candidate,
      ),
    ),
  );
}

/// Copia só [SduiNode.properties] do nó [nodeId] da candidata para o
/// rascunho — nunca `events`, `safeArea` ou metadados do [ContentSpec], que
/// esta v1 sinaliza como diferenças não copiáveis. `id`, `type`, `child` e
/// `children` do resultado seguem exatamente os de [base]: mesmo que a
/// candidata tenha [nodeId] sob outro pai, o resultado nunca reparenta —
/// ele nunca lê a topologia da candidata, só o valor de `properties`.
Either<ComparisonFailure, ContentSpec> copyComparableNodeProperties(
  ContentSpec base,
  ContentSpec candidate,
  String nodeId,
) {
  final baseIndex = _TreeIndex.of(base.root);
  final candidateIndex = _TreeIndex.of(candidate.root);

  final duplicateFailure = _duplicateFailure(baseIndex, candidateIndex);
  if (duplicateFailure != null) return Left(duplicateFailure);

  final baseNode = baseIndex.byId[nodeId];
  final candidateNode = candidateIndex.byId[nodeId];
  if (baseNode == null || candidateNode == null) {
    return Left(NodeNotFoundForCopyFailure(nodeId));
  }
  if (baseNode.type != candidateNode.type) {
    return Left(
      NodeTypeMismatchForCopyFailure(
        nodeId: nodeId,
        baseType: baseNode.type,
        candidateType: candidateNode.type,
      ),
    );
  }
  if (!_hasOnlyStringKeys(candidateNode.properties)) {
    return Left(NonStringPropertyKeyForCopyFailure(nodeId));
  }

  final copiedProperties = _deepCloneProperties(candidateNode.properties);
  final updatedRoot = _withNodeProperties(
    base.root!,
    nodeId,
    copiedProperties,
  );
  return Right(base.copyWith(root: () => updatedRoot));
}

DuplicateNodeIdComparisonFailure? _duplicateFailure(
  _TreeIndex baseIndex,
  _TreeIndex candidateIndex,
) {
  if (baseIndex.duplicateIds.isEmpty && candidateIndex.duplicateIds.isEmpty) {
    return null;
  }
  return DuplicateNodeIdComparisonFailure(
    baseDuplicateIds: baseIndex.duplicateIds,
    candidateDuplicateIds: candidateIndex.duplicateIds,
  );
}

NodeDiff _diffNode(
  SduiNode base,
  SduiNode candidate, {
  required String? baseParentId,
  required String? candidateParentId,
}) {
  return NodeDiff(
    nodeId: base.id,
    baseType: base.type,
    candidateType: candidate.type,
    propertiesChanged: !_deepEquals(base.properties, candidate.properties),
    eventsChanged: !_deepEquals(base.events, candidate.events),
    childOrderChanged: _childOrderChanged(base, candidate),
    baseParentId: baseParentId,
    candidateParentId: candidateParentId,
  );
}

/// `shared` é a interseção de `baseIds` e `candidateIds`; como
/// [compareContentSpecs] só chega aqui depois de garantir que nenhuma
/// árvore tem `id` duplicado, cada id de `shared` ocorre uma única vez em
/// cada lista de origem — por isso as duas listas filtradas abaixo sempre
/// saem do mesmo tamanho.
bool _childOrderChanged(SduiNode base, SduiNode candidate) {
  final baseIds = [for (final child in base.children) child.id];
  final candidateIds = [for (final child in candidate.children) child.id];
  final shared = baseIds.toSet().intersection(candidateIds.toSet());

  final baseShared = baseIds.where(shared.contains).toList();
  final candidateShared = candidateIds.where(shared.contains).toList();

  for (var i = 0; i < baseShared.length; i++) {
    if (baseShared[i] != candidateShared[i]) return true;
  }
  return false;
}

Set<String> _changedContentMetadataFields(
  ContentSpec base,
  ContentSpec candidate,
) {
  final changed = <String>{};
  if (base.specVersion != candidate.specVersion) changed.add('specVersion');
  if (base.id != candidate.id) changed.add('id');
  if (base.name != candidate.name) changed.add('name');
  if (base.slug != candidate.slug) changed.add('slug');
  if (base.description != candidate.description) changed.add('description');
  return changed;
}

SduiNode _withNodeProperties(
  SduiNode node,
  String targetId,
  Map<String, dynamic> newProperties,
) {
  final child = node.child == null
      ? null
      : _withNodeProperties(node.child!, targetId, newProperties);
  final children = [
    for (final each in node.children)
      _withNodeProperties(each, targetId, newProperties),
  ];
  final rebuilt = node.copyWith(child: () => child, children: children);
  return rebuilt.id == targetId
      ? rebuilt.copyWith(properties: newProperties)
      : rebuilt;
}

class _TreeIndex {
  const _TreeIndex(this.byId, this.parentIdById, this.duplicateIds);

  factory _TreeIndex.of(SduiNode? root) {
    final byId = <String, SduiNode>{};
    final parentIdById = <String, String?>{};
    final duplicates = <String>{};

    void visit(SduiNode node, String? parentId) {
      if (byId.containsKey(node.id)) {
        duplicates.add(node.id);
      } else {
        byId[node.id] = node;
        parentIdById[node.id] = parentId;
      }
      if (node.child != null) visit(node.child!, node.id);
      for (final each in node.children) {
        visit(each, node.id);
      }
    }

    if (root != null) visit(root, null);
    return _TreeIndex(byId, parentIdById, duplicates);
  }

  final Map<String, SduiNode> byId;
  final Map<String, String?> parentIdById;
  final Set<String> duplicateIds;
}

Map<String, dynamic> _deepCloneProperties(Map<String, dynamic> source) {
  return {
    for (final entry in source.entries) entry.key: _deepClone(entry.value),
  };
}

/// Pré-condição garantida por [_hasOnlyStringKeys] no único chamador —
/// por isso o `as String` abaixo nunca lança.
Object? _deepClone(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key as String: _deepClone(entry.value),
    };
  }
  if (value is List) {
    return [for (final each in value) _deepClone(each)];
  }
  return value;
}

bool _hasOnlyStringKeys(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key is! String) return false;
      if (!_hasOnlyStringKeys(entry.value)) return false;
    }
    return true;
  }
  if (value is List) {
    return value.every(_hasOnlyStringKeys);
  }
  return true;
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Chaves de [SduiNode.properties] que diferem entre [base] e [candidate] —
/// união das duas chaves, mantendo só as que [_deepEquals] considera
/// diferentes. Reusa a mesma comparação de [_diffNode]: outra implementação
/// aqui divergiria de [NodeDiff.propertiesChanged], podendo marcar o nó como
/// alterado sem nenhuma chave correspondente no resultado.
Set<String> changedPropertyKeys(SduiNode base, SduiNode candidate) {
  final keys = base.properties.keys.toSet().union(
    candidate.properties.keys.toSet(),
  );
  return {
    for (final key in keys)
      if (!_deepEquals(base.properties[key], candidate.properties[key])) key,
  };
}
