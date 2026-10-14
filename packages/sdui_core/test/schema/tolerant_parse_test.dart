import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _spec() => {
  'specVersion': 1,
  'kind': 'content',
  'id': 'ct_1',
  'name': 'Teste',
  'slug': 'teste',
  'root': {
    'id': 'n1',
    'type': 'column',
    'children': [
      {
        'id': 'n2',
        'type': 'text',
        'props': {'data': 'oi', 'propFutura': 1},
      },
      {
        'id': 'n3',
        'type': 'futureWidget',
        'props': {'x': 1},
      },
      {
        'id': 'n4',
        'type': 'text',
        'props': {'data': 'tchau'},
      },
    ],
  },
};

void main() {
  test('modo tolerante mantém irmãos e preserva o nó desconhecido', () {
    final content = parseContentSpec(_spec(), tolerant: true).toNullable();
    expect(content, isNotNull);
    final kids = content!.root!.children;
    expect(kids.map((n) => n.id), ['n2', 'n3', 'n4']);
    expect(kids[1].type, 'futureWidget');
    expect(kids[1].properties['x'], 1);
  });

  test('modo estrito rejeita tipo fora do catálogo', () {
    expect(parseContentSpec(_spec()).isLeft(), isTrue);
  });

  test('modo tolerante ainda reprova id ausente', () {
    final spec = _spec();
    ((spec['root'] as Map)['children'] as List)[1] = {'type': 'futureWidget'};
    expect(parseContentSpec(spec, tolerant: true).isLeft(), isTrue);
  });
}
