import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('safeAreaDescriptor', () {
    test('fica fora do catálogo: não é tipo de nó nem entra na paleta', () {
      expect(widgetCatalog.containsKey('safeArea'), isFalse);
      expect(descriptorFor('safeArea'), isNull);
    });

    test('nó com type safeArea é recusado pelo schema', () {
      final result = parseContentSpec({
        'specVersion': kSpecVersion,
        'kind': 'content',
        'id': 'ct',
        'name': 'N',
        'slug': 'n',
        'root': {'id': 'sa', 'type': 'safeArea'},
      });
      expect(result.isLeft(), isTrue);
    });

    test('nasce ligada, respeitando os quatro lados', () {
      final defaults = defaultProperties(safeAreaDescriptor);
      expect(defaults['enabled'], isTrue);
      expect(defaults['top'], isTrue);
      expect(defaults['bottom'], isTrue);
      expect(defaults['left'], isTrue);
      expect(defaults['right'], isTrue);
      expect(defaults['maintainBottomViewPadding'], isFalse);
    });

    test('nenhuma prop de página aceita binding', () {
      expect(
        safeAreaDescriptor.fields.every((field) => !field.isBindable),
        isTrue,
      );
    });

    test('defaultValueOf resolve a ausência da chave', () {
      expect(safeAreaDescriptor.defaultValueOf('top'), isTrue);
      expect(safeAreaDescriptor.defaultValueOf('minimum'), isNull);
      expect(safeAreaDescriptor.fieldOf('inexistente'), isNull);
    });
  });
}
