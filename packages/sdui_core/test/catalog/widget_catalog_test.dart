import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('widgetCatalog', () {
    test('tem os primitivos do catálogo (14 do I1 + form inputs)', () {
      expect(
        widgetCatalog.keys,
        containsAll(<String>[
          'container',
          'column',
          'row',
          'stack',
          'text',
          'image',
          'icon',
          'button',
          'textField',
          'switch',
          'checkbox',
          'card',
          'divider',
          'sizedBox',
          'padding',
          'center',
          'spacer',
        ]),
      );
      expect(widgetCatalog, hasLength(17));
    });

    test('controles de formulário são folhas na categoria Interação', () {
      for (final type in <String>['textField', 'switch', 'checkbox']) {
        final descriptor = descriptorFor(type)!;
        expect(descriptor.slot, SlotKind.none, reason: type);
        expect(descriptor.category, WidgetCategories.interaction, reason: type);
      }
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
            expect(
              field.enumValues,
              isNotEmpty,
              reason: '${descriptor.type}.${field.key}',
            );
            if (field.defaultValue != null) {
              expect(
                field.enumValues,
                contains(field.defaultValue),
                reason: '${descriptor.type}.${field.key}',
              );
            }
          } else {
            expect(
              field.enumValues,
              isEmpty,
              reason: '${descriptor.type}.${field.key}',
            );
          }
        }
      }
    });

    test('textField expõe props abrangentes e não expõe mais filled', () {
      final descriptor = descriptorFor('textField')!;
      final byKey = {for (final f in descriptor.fields) f.key: f};

      expect(byKey.containsKey('filled'), isFalse);

      final borderStyle = byKey['borderStyle']!;
      expect(borderStyle.kind, FieldKind.enumeration);
      expect(borderStyle.enumValues, <String>[
        'outline',
        'underline',
        'filled',
      ]);
      expect(borderStyle.defaultValue, 'outline');

      final keyboardType = byKey['keyboardType']!;
      expect(keyboardType.kind, FieldKind.enumeration);
      expect(keyboardType.enumValues, <String>[
        'text',
        'number',
        'email',
        'phone',
        'url',
      ]);
      expect(keyboardType.defaultValue, 'text');

      final maxLength = byKey['maxLength']!;
      expect(maxLength.kind, FieldKind.intNum);
      expect(maxLength.defaultValue, isNull);

      final prefixIcon = byKey['prefixIcon']!;
      expect(prefixIcon.kind, FieldKind.iconName);
      expect(prefixIcon.defaultValue, isNull);
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
      expect(
        node.properties.containsKey('color'),
        isFalse,
        reason: 'campo sem default não entra',
      );
    });

    test('nó default passa na validação do schema', () {
      for (final type in widgetCatalog.keys) {
        final node = defaultNode(type, id: 'nd_$type');
        final result = parseNode(node.toJson());

        expect(
          result.isRight(),
          isTrue,
          reason: '$type: ${result.getLeft().toNullable()}',
        );
      }
    });

    test('lança para tipo fora do catálogo', () {
      expect(() => defaultNode('carousel3d', id: 'x'), throwsArgumentError);
    });
  });
}
