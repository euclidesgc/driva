import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  test('todo campo do catálogo declara uma seção válida', () {
    for (final d in widgetCatalog.values) {
      for (final f in d.fields) {
        expect(
          FieldSections.isValid(f.section),
          isTrue,
          reason: '${d.type}.${f.key}',
        );
      }
    }
  });

  test('padding é comum e name faz round-trip no nó', () {
    final pad = widgetCatalog.values
        .expand((d) => d.fields)
        .firstWhere((f) => f.key == 'padding');
    expect(pad.section, FieldSections.comum);

    const node = SduiNode(id: 'a', type: 'container', name: 'Cabeçalho');
    expect(node.toJson()['name'], 'Cabeçalho');
    expect(
      const SduiNode(id: 'a', type: 'container').toJson(),
      isNot(contains('name')),
    );
    expect(node.copyWith(name: () => null).name, isNull);
    expect(node.copyWith(id: 'b').name, 'Cabeçalho');
  });
}
