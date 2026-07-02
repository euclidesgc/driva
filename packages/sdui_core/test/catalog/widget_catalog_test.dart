import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('widgetCatalog', () {
    test('tem os 14 primitivos do I1', () {
      expect(widgetCatalog.keys, containsAll(<String>[
        'container',
        'column',
        'row',
        'stack',
        'text',
        'image',
        'icon',
        'button',
        'card',
        'divider',
        'sizedBox',
        'padding',
        'center',
        'spacer',
      ]));
      expect(widgetCatalog, hasLength(14));
    });

    test('descriptor é consistente: type espelha a chave', () {
      for (final entry in widgetCatalog.entries) {
        expect(entry.value.type, entry.key);
      }
    });

    test('todo campo enumeration tem enumValues (e só ele)', () {
      for (final descriptor in widgetCatalog.values) {
        for (final field in descriptor.fields) {
          if (field.kind == FieldKind.enumeration) {
            expect(field.enumValues, isNotEmpty,
                reason: '${descriptor.type}.${field.key}');
            if (field.defaultValue != null) {
              expect(field.enumValues, contains(field.defaultValue),
                  reason: '${descriptor.type}.${field.key}');
            }
          } else {
            expect(field.enumValues, isEmpty,
                reason: '${descriptor.type}.${field.key}');
          }
        }
      }
    });

    test('descriptorFor devolve null para tipo desconhecido', () {
      expect(descriptorFor('carousel3d'), isNull);
      expect(descriptorFor('text'), isNotNull);
    });
  });

  group('defaultNode', () {
    test('pré-preenche as props com os defaults do catálogo', () {
      final node = defaultNode('text', id: 'nd_1');

      expect(node.id, 'nd_1');
      expect(node.type, 'text');
      expect(node.properties['data'], 'Texto');
      expect(node.properties['fontSize'], 14.0);
      expect(node.properties.containsKey('color'), isFalse,
          reason: 'campo sem default não entra');
    });

    test('nó default passa na validação do schema', () {
      for (final type in widgetCatalog.keys) {
        final node = defaultNode(type, id: 'nd_$type');
        final result = parseNode(node.toJson());

        expect(result.isRight(), isTrue,
            reason: '$type: ${result.getLeft().toNullable()}');
      }
    });

    test('lança para tipo fora do catálogo', () {
      expect(() => defaultNode('carousel3d', id: 'x'), throwsArgumentError);
    });
  });
}
