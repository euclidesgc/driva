import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/multi_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  const a = SduiNode(id: 'a', type: 'text', properties: {'color': '#FF0000'});
  const b = SduiNode(id: 'b', type: 'text', properties: {'color': '#00FF00'});
  const c = SduiNode(id: 'c', type: 'container');

  test('commonFields de tipos iguais devolve todos os campos do tipo', () {
    final keys = commonFields([a, b]).map((f) => f.key).toSet();
    expect(keys, descriptorFor('text')!.fields.map((f) => f.key).toSet());
  });

  test('commonFields de tipos diferentes é a interseção', () {
    final text = descriptorFor('text')!.fields.map((f) => f.key).toSet();
    final container = descriptorFor('container')!.fields.map((f) => f.key);
    final keys = commonFields([a, c]).map((f) => f.key).toSet();
    expect(keys, text.intersection(container.toSet()));
  });

  test('commonFields vazio sem nós', () {
    expect(commonFields(const []), isEmpty);
  });

  test('mixedValue detecta valores divergentes e iguais', () {
    expect(mixedValue([a, b], 'color'), isTrue);
    expect(mixedValue([a, a], 'color'), isFalse);
    expect(mixedValue([a], 'color'), isFalse);
  });
}
