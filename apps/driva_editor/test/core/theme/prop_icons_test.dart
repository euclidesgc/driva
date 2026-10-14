import 'package:driva_editor/core/theme/prop_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Iterable<PropField> _fieldsNamed(String key) => widgetCatalog.values
    .expand((descriptor) => descriptor.fields)
    .where((field) => field.key == key);

PropField _fieldOf(String type, String key) =>
    widgetCatalog[type]!.fields.singleWhere((field) => field.key == key);

bool _allOptionsHaveIcon(PropField field) =>
    field.options.every((option) => PropIcons.has(option.iconName));

void main() {
  group('PropIcons: Box Fit da imagem', () {
    test('toda opção de image.fit tem iconName resolvido', () {
      final field = _fieldOf('image', 'fit');

      expect(field.options, hasLength(7));
      for (final option in field.options) {
        expect(PropIcons.has(option.iconName), isTrue, reason: option.value);
      }
    });
  });

  group('PropIcons: enums visuais curtos', () {
    const shortEnumKeys = [
      'mainAxisAlignment',
      'crossAxisAlignment',
      'mainAxisSize',
      'textAlign',
      'scrollDirection',
    ];

    for (final key in shortEnumKeys) {
      test('todas as opções de $key têm ícone resolvido', () {
        final fields = _fieldsNamed(key).toList();

        expect(fields, isNotEmpty);
        for (final field in fields) {
          expect(_allOptionsHaveIcon(field), isTrue, reason: key);
        }
      });
    }
  });

  group('PropIcons: enums que seguem em dropdown', () {
    const dropdownFields = [
      ('stack', 'fit'),
      ('text', 'overflow'),
      ('text', 'fontWeight'),
    ];

    for (final (type, key) in dropdownFields) {
      test('$type.$key tem ao menos uma opção sem iconName', () {
        final field = _fieldOf(type, key);

        expect(field.options.any((option) => option.iconName == null), isTrue);
      });
    }
  });
}
