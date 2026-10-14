import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('PropValueType.feeds', () {
    final cases = <(PropValueType, PropValueType, bool)>[
      (PropValueType.text, PropValueType.text, true),
      (PropValueType.color, PropValueType.color, true),
      (PropValueType.any, PropValueType.color, true),
      (PropValueType.any, PropValueType.boolean, true),
      (PropValueType.declared, PropValueType.boolean, true),
      (PropValueType.declared, PropValueType.text, true),
      (PropValueType.integer, PropValueType.decimal, true),
      (PropValueType.text, PropValueType.color, false),
      (PropValueType.decimal, PropValueType.integer, false),
      (PropValueType.boolean, PropValueType.text, false),
      (PropValueType.option, PropValueType.text, false),
      (PropValueType.icon, PropValueType.text, false),
    ];

    for (final (source, expected, result) in cases) {
      test('${source.name} → ${expected.name} é $result', () {
        expect(source.feeds(expected), result);
      });
    }
  });

  group('FieldKind.valueType', () {
    final expected = <FieldKind, PropValueType>{
      FieldKind.string: PropValueType.text,
      FieldKind.doubleNum: PropValueType.decimal,
      FieldKind.intNum: PropValueType.integer,
      FieldKind.dimension: PropValueType.dimension,
      FieldKind.boolean: PropValueType.boolean,
      FieldKind.color: PropValueType.color,
      FieldKind.enumeration: PropValueType.option,
      FieldKind.edgeInsets: PropValueType.spacing,
      FieldKind.alignment: PropValueType.alignment,
      FieldKind.iconName: PropValueType.icon,
    };

    for (final MapEntry(key: kind, value: type) in expected.entries) {
      test('${kind.name} → ${type.name}', () {
        expect(kind.valueType, type);
      });
    }

    test('a tabela cobre todo valor de FieldKind', () {
      expect(expected.keys, unorderedEquals(FieldKind.values));
    });
  });
}
