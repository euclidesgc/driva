import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

const ContentSpec _emptySpec = ContentSpec(
  specVersion: 1,
  id: 'content-1',
  name: 'Base',
  slug: 'base-slug',
);

ContentSpec _withRoot(ContentSpec spec, SduiNode? root) =>
    spec.copyWith(root: () => root);

/// Retrato profundo, independente de qualquer `Map`/`List` mutável de
/// origem — ao contrário de `toJson()` (que embute `properties`/`events`
/// por referência), comparar contra este retrato pega mutação in-place.
Object? _deepCopyValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key as String: _deepCopyValue(entry.value),
    };
  }
  if (value is List) {
    return [for (final each in value) _deepCopyValue(each)];
  }
  return value;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) =>
    _deepCopyValue(source)! as Map<String, dynamic>;

SduiNode _deepCopyNode(SduiNode node) => SduiNode(
  id: node.id,
  type: node.type,
  properties: _deepCopyMap(node.properties),
  events: _deepCopyMap(node.events),
  child: node.child == null ? null : _deepCopyNode(node.child!),
  children: [for (final child in node.children) _deepCopyNode(child)],
);

ContentSpec _deepCopySpec(ContentSpec spec) => ContentSpec(
  specVersion: spec.specVersion,
  id: spec.id,
  name: spec.name,
  slug: spec.slug,
  description: spec.description,
  safeArea: _deepCopyMap(spec.safeArea),
  root: spec.root == null ? null : _deepCopyNode(spec.root!),
);

void main() {
  group('compareContentSpecs', () {
    test('root nulo nos dois lados não gera diferenças', () {
      final result = compareContentSpecs(_emptySpec, _emptySpec);

      final comparison = result.getRight().toNullable()!;
      expect(comparison.nodeDiffs, isEmpty);
      expect(comparison.nodesOnlyInBase, isEmpty);
      expect(comparison.nodesOnlyInCandidate, isEmpty);
      expect(comparison.hasDifferences, isFalse);
    });

    test('spec de nó único e idêntico não reporta alteração', () {
      final spec = _withRoot(
        _emptySpec,
        const SduiNode(id: 'root', type: 'text', properties: {'text': 'A'}),
      );

      final comparison = compareContentSpecs(
        spec,
        spec,
      ).getRight().toNullable()!;

      expect(comparison.nodeDiffs, hasLength(1));
      expect(comparison.nodeDiffs.single.hasChanges, isFalse);
      expect(comparison.hasDifferences, isFalse);
    });

    test(
      'diferença na própria raiz: IDs distintos tornam as duas exclusivas',
      () {
        final base = _withRoot(
          _emptySpec,
          const SduiNode(id: 'root-a', type: 'text'),
        );
        final candidate = _withRoot(
          _emptySpec,
          const SduiNode(id: 'root-b', type: 'text'),
        );

        final comparison = compareContentSpecs(
          base,
          candidate,
        ).getRight().toNullable()!;

        expect(comparison.nodesOnlyInBase, {'root-a'});
        expect(comparison.nodesOnlyInCandidate, {'root-b'});
        expect(comparison.nodeDiffs, isEmpty);
      },
    );

    test('propriedade alterada aparece isolada no NodeDiff do nó', () {
      final base = _withRoot(
        _emptySpec,
        const SduiNode(id: 'root', type: 'text', properties: {'text': 'A'}),
      );
      final candidate = _withRoot(
        _emptySpec,
        const SduiNode(id: 'root', type: 'text', properties: {'text': 'B'}),
      );

      final diff = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!.nodeDiffs.single;

      expect(diff.propertiesChanged, isTrue);
      expect(diff.eventsChanged, isFalse);
      expect(diff.typeChanged, isFalse);
    });

    test(
      'JSON aninhado igual em profundidade não conta como propriedade alterada',
      () {
        final base = _withRoot(
          _emptySpec,
          const SduiNode(
            id: 'root',
            type: 'text',
            properties: {
              'style': {
                'padding': {'left': 8, 'right': 8},
              },
            },
          ),
        );
        final candidate = _withRoot(
          _emptySpec,
          const SduiNode(
            id: 'root',
            type: 'text',
            properties: {
              'style': {
                'padding': {'left': 8, 'right': 8},
              },
            },
          ),
        );

        final diff = compareContentSpecs(
          base,
          candidate,
        ).getRight().toNullable()!.nodeDiffs.single;

        expect(diff.propertiesChanged, isFalse);
      },
    );

    test('evento alterado aparece isolado no NodeDiff do nó', () {
      final base = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'button',
          events: {
            'onTap': {'type': 'navigate', 'target': 'a'},
          },
        ),
      );
      final candidate = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'button',
          events: {
            'onTap': {'type': 'navigate', 'target': 'b'},
          },
        ),
      );

      final diff = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!.nodeDiffs.single;

      expect(diff.eventsChanged, isTrue);
      expect(diff.propertiesChanged, isFalse);
      expect(diff.typeChanged, isFalse);
    });

    test('tipo alterado aparece isolado no NodeDiff do nó', () {
      final base = _withRoot(
        _emptySpec,
        const SduiNode(id: 'x', type: 'text', properties: {'text': 'A'}),
      );
      final candidate = _withRoot(
        _emptySpec,
        const SduiNode(id: 'x', type: 'icon', properties: {'text': 'A'}),
      );

      final diff = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!.nodeDiffs.single;

      expect(diff.typeChanged, isTrue);
      expect(diff.baseType, 'text');
      expect(diff.candidateType, 'icon');
      expect(diff.propertiesChanged, isFalse);
    });

    test('nó só na base fica de fora da candidata', () {
      final base = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'column',
          children: [
            SduiNode(id: 'a', type: 'text'),
            SduiNode(id: 'b', type: 'text'),
          ],
        ),
      );
      final candidate = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'column',
          children: [SduiNode(id: 'a', type: 'text')],
        ),
      );

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;

      expect(comparison.nodesOnlyInBase, {'b'});
      expect(comparison.nodesOnlyInCandidate, isEmpty);
    });

    test('nó só na candidata não existia na base', () {
      final base = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'column',
          children: [SduiNode(id: 'a', type: 'text')],
        ),
      );
      final candidate = _withRoot(
        _emptySpec,
        const SduiNode(
          id: 'root',
          type: 'column',
          children: [
            SduiNode(id: 'a', type: 'text'),
            SduiNode(id: 'b', type: 'text'),
          ],
        ),
      );

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;

      expect(comparison.nodesOnlyInCandidate, {'b'});
      expect(comparison.nodesOnlyInBase, isEmpty);
    });

    test('safeArea alterada é reportada', () {
      const base = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Base',
        slug: 'base-slug',
        safeArea: {'top': true},
      );
      const candidate = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Base',
        slug: 'base-slug',
        safeArea: {'top': false},
      );

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;

      expect(comparison.safeAreaChanged, isTrue);
    });

    test('safeArea com mesmo conteúdo em mapas distintos não é alteração', () {
      const base = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Base',
        slug: 'base-slug',
        safeArea: {'top': true},
      );
      const candidate = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Base',
        slug: 'base-slug',
        safeArea: {'top': true},
      );

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;

      expect(comparison.safeAreaChanged, isFalse);
    });

    test('metadado do ContentSpec alterado é reportado pelo nome do campo', () {
      const base = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Nome base',
        slug: 'base-slug',
      );
      const candidate = ContentSpec(
        specVersion: 1,
        id: 'content-1',
        name: 'Nome candidata',
        slug: 'base-slug',
      );

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;

      expect(comparison.changedContentMetadataFields, {'name'});
    });

    test('ordem de filhos diferente é reportada e não altera as entradas', () {
      final base = _withRoot(
        _emptySpec,
        SduiNode(
          id: 'root',
          type: 'column',
          properties: Map<String, dynamic>.of({'text': 'root-base'}),
          children: const [
            SduiNode(id: 'a', type: 'text'),
            SduiNode(id: 'b', type: 'text'),
          ],
        ),
      );
      final candidate = _withRoot(
        _emptySpec,
        SduiNode(
          id: 'root',
          type: 'column',
          properties: Map<String, dynamic>.of({'text': 'root-candidate'}),
          children: const [
            SduiNode(id: 'b', type: 'text'),
            SduiNode(id: 'a', type: 'text'),
          ],
        ),
      );
      final baseSnapshot = _deepCopySpec(base);
      final candidateSnapshot = _deepCopySpec(candidate);

      final comparison = compareContentSpecs(
        base,
        candidate,
      ).getRight().toNullable()!;
      final rootDiff = comparison.nodeDiffs.firstWhere(
        (d) => d.nodeId == 'root',
      );

      expect(rootDiff.childOrderChanged, isTrue);
      expect(base, baseSnapshot);
      expect(candidate, candidateSnapshot);
      expect(base.root!.children.map((n) => n.id), ['a', 'b']);
      expect(candidate.root!.children.map((n) => n.id), ['b', 'a']);
    });

    test(
      'nó que muda de pai é reportado, mesmo com tipo e propriedades iguais',
      () {
        final base = _withRoot(
          _emptySpec,
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(
                id: 'a',
                type: 'container',
                child: SduiNode(
                  id: 'x',
                  type: 'text',
                  properties: {'text': 'X'},
                ),
              ),
              SduiNode(id: 'b', type: 'container'),
            ],
          ),
        );
        final candidate = _withRoot(
          _emptySpec,
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(id: 'a', type: 'container'),
              SduiNode(
                id: 'b',
                type: 'container',
                child: SduiNode(
                  id: 'x',
                  type: 'text',
                  properties: {'text': 'X'},
                ),
              ),
            ],
          ),
        );

        final comparison = compareContentSpecs(
          base,
          candidate,
        ).getRight().toNullable()!;
        final diffX = comparison.nodeDiffs.firstWhere((d) => d.nodeId == 'x');

        expect(diffX.parentChanged, isTrue);
        expect(diffX.baseParentId, 'a');
        expect(diffX.candidateParentId, 'b');
        expect(diffX.propertiesChanged, isFalse);
        expect(diffX.typeChanged, isFalse);
        expect(comparison.hasDifferences, isTrue);
      },
    );

    group('ID duplicado bloqueia a comparação inteira', () {
      test(
        'duplicado na base devolve DuplicateNodeIdComparisonFailure '
        'e preserva as entradas',
        () {
          final base = _withRoot(
            _emptySpec,
            SduiNode(
              id: 'root',
              type: 'column',
              properties: Map<String, dynamic>.of({'text': 'root-base'}),
              children: const [
                SduiNode(id: 'dup', type: 'text'),
                SduiNode(id: 'dup', type: 'icon'),
              ],
            ),
          );
          final candidate = _withRoot(
            _emptySpec,
            SduiNode(
              id: 'root',
              type: 'text',
              properties: Map<String, dynamic>.of({'text': 'root-candidate'}),
            ),
          );
          final baseSnapshot = _deepCopySpec(base);
          final candidateSnapshot = _deepCopySpec(candidate);

          final result = compareContentSpecs(base, candidate);

          expect(result.isLeft(), isTrue);
          final failure = result.getLeft().toNullable();
          expect(failure, isA<DuplicateNodeIdComparisonFailure>());
          expect(
            (failure! as DuplicateNodeIdComparisonFailure).baseDuplicateIds,
            {'dup'},
          );
          expect(
            (failure as DuplicateNodeIdComparisonFailure).candidateDuplicateIds,
            isEmpty,
          );
          expect(base, baseSnapshot);
          expect(candidate, candidateSnapshot);
        },
      );

      test('duplicado na candidata também bloqueia', () {
        final base = _withRoot(
          _emptySpec,
          SduiNode(
            id: 'root',
            type: 'text',
            properties: Map<String, dynamic>.of({'text': 'root-base'}),
          ),
        );
        final candidate = _withRoot(
          _emptySpec,
          SduiNode(
            id: 'root',
            type: 'column',
            properties: Map<String, dynamic>.of({'text': 'root-candidate'}),
            children: const [
              SduiNode(id: 'dup', type: 'text'),
              SduiNode(id: 'dup', type: 'icon'),
            ],
          ),
        );
        final baseSnapshot = _deepCopySpec(base);
        final candidateSnapshot = _deepCopySpec(candidate);

        final result = compareContentSpecs(base, candidate);

        expect(result.isLeft(), isTrue);
        final failure =
            result.getLeft().toNullable()! as DuplicateNodeIdComparisonFailure;
        expect(failure.candidateDuplicateIds, {'dup'});
        expect(failure.baseDuplicateIds, isEmpty);
        expect(base, baseSnapshot);
        expect(candidate, candidateSnapshot);
      });
    });
  });

  group('copyComparableNodeProperties', () {
    ContentSpec buildSpec(SduiNode root) => _withRoot(_emptySpec, root);

    test(
      'copia propriedades preservando id, tipo, filhos e posição do rascunho',
      () {
        final base = buildSpec(
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(
                id: 'x',
                type: 'text',
                properties: {
                  'text': 'old',
                  'style': {'size': 10},
                },
              ),
              SduiNode(id: 'y', type: 'icon'),
            ],
          ),
        );
        final candidate = buildSpec(
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(
                id: 'x',
                type: 'text',
                properties: {
                  'text': 'new',
                  'style': {'size': 20},
                },
              ),
              SduiNode(id: 'z', type: 'divider'),
            ],
          ),
        );

        final result = copyComparableNodeProperties(base, candidate, 'x');

        final updated = result.getRight().toNullable()!;
        final updatedChildren = updated.root!.children;
        expect(updatedChildren, hasLength(2));
        expect(updatedChildren[0].id, 'x');
        expect(updatedChildren[0].type, 'text');
        expect(updatedChildren[0].properties, {
          'text': 'new',
          'style': {'size': 20},
        });
        expect(updatedChildren[1].id, 'y');
        expect(updated.name, base.name);
      },
    );

    test(
      'cópia é profunda: alterar o resultado não altera a candidata original',
      () {
        final base = buildSpec(
          SduiNode(
            id: 'x',
            type: 'text',
            properties: Map<String, dynamic>.of({
              'style': <String, dynamic>{},
            }),
          ),
        );
        final originalNested = <String, dynamic>{'value': 1};
        final candidateNode = SduiNode(
          id: 'x',
          type: 'text',
          properties: {
            'style': {'nested': originalNested},
          },
        );
        final candidate = buildSpec(candidateNode);
        final candidateSnapshot = _deepCopySpec(candidate);

        final updated = copyComparableNodeProperties(
          base,
          candidate,
          'x',
        ).getRight().toNullable()!;
        final updatedStyle =
            updated.root!.properties['style']! as Map<String, dynamic>;
        (updatedStyle['nested']! as Map<String, dynamic>)['value'] = 999;

        expect(originalNested['value'], 1);
        expect(candidate, candidateSnapshot);
      },
    );

    test('não muta base nem candidate', () {
      final base = buildSpec(
        SduiNode(
          id: 'x',
          type: 'text',
          properties: Map<String, dynamic>.of({'text': 'old'}),
        ),
      );
      final candidate = buildSpec(
        SduiNode(
          id: 'x',
          type: 'text',
          properties: Map<String, dynamic>.of({'text': 'new'}),
        ),
      );
      final baseSnapshot = _deepCopySpec(base);
      final candidateSnapshot = _deepCopySpec(candidate);

      copyComparableNodeProperties(base, candidate, 'x');

      expect(base, baseSnapshot);
      expect(candidate, candidateSnapshot);
    });

    test('recusa quando o ID não existe na base', () {
      final base = buildSpec(const SduiNode(id: 'root', type: 'text'));
      final candidate = buildSpec(const SduiNode(id: 'x', type: 'text'));

      final result = copyComparableNodeProperties(base, candidate, 'x');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        equals(const NodeNotFoundForCopyFailure('x')),
      );
    });

    test('recusa quando o ID não existe na candidata', () {
      final base = buildSpec(const SduiNode(id: 'x', type: 'text'));
      final candidate = buildSpec(const SduiNode(id: 'root', type: 'text'));

      final result = copyComparableNodeProperties(base, candidate, 'x');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        equals(const NodeNotFoundForCopyFailure('x')),
      );
    });

    test('recusa quando o tipo difere entre base e candidata', () {
      final base = buildSpec(const SduiNode(id: 'x', type: 'text'));
      final candidate = buildSpec(const SduiNode(id: 'x', type: 'icon'));

      final result = copyComparableNodeProperties(base, candidate, 'x');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        equals(
          const NodeTypeMismatchForCopyFailure(
            nodeId: 'x',
            baseType: 'text',
            candidateType: 'icon',
          ),
        ),
      );
    });

    test('recusa quando a candidata tem chave de propriedade não-String', () {
      final base = buildSpec(
        const SduiNode(id: 'x', type: 'text', properties: {'text': 'old'}),
      );
      const candidateNode = SduiNode(
        id: 'x',
        type: 'text',
        properties: {
          'style': <dynamic, dynamic>{1: 'not-a-string-key'},
        },
      );
      final candidate = buildSpec(candidateNode);

      final result = copyComparableNodeProperties(base, candidate, 'x');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        equals(const NonStringPropertyKeyForCopyFailure('x')),
      );
    });

    test(
      'copiar propriedades não reparenta o nó mesmo quando a candidata o moveu',
      () {
        final base = buildSpec(
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(
                id: 'a',
                type: 'container',
                child: SduiNode(
                  id: 'x',
                  type: 'text',
                  properties: {'text': 'old'},
                ),
              ),
              SduiNode(id: 'b', type: 'container'),
            ],
          ),
        );
        final candidate = buildSpec(
          const SduiNode(
            id: 'root',
            type: 'column',
            children: [
              SduiNode(id: 'a', type: 'container'),
              SduiNode(
                id: 'b',
                type: 'container',
                child: SduiNode(
                  id: 'x',
                  type: 'text',
                  properties: {'text': 'new'},
                ),
              ),
            ],
          ),
        );

        final updated = copyComparableNodeProperties(
          base,
          candidate,
          'x',
        ).getRight().toNullable()!;

        expect(findNode(updated.root!, 'a')!.child?.id, 'x');
        expect(findNode(updated.root!, 'b')!.child, isNull);
        expect(findNode(updated.root!, 'x')!.properties['text'], 'new');
      },
    );

    test('ID duplicado bloqueia a cópia, e nenhum nó é modificado', () {
      final base = buildSpec(
        SduiNode(
          id: 'root',
          type: 'column',
          properties: Map<String, dynamic>.of({'text': 'root-base'}),
          children: const [
            SduiNode(id: 'dup', type: 'text'),
            SduiNode(id: 'dup', type: 'icon'),
          ],
        ),
      );
      final candidate = buildSpec(
        SduiNode(
          id: 'root',
          type: 'text',
          properties: Map<String, dynamic>.of({'text': 'root-cand'}),
        ),
      );
      final baseSnapshot = _deepCopySpec(base);
      final candidateSnapshot = _deepCopySpec(candidate);

      final result = copyComparableNodeProperties(base, candidate, 'root');

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<DuplicateNodeIdComparisonFailure>(),
      );
      expect(base, baseSnapshot);
      expect(candidate, candidateSnapshot);
    });
  });
}
