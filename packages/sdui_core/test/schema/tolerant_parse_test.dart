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

  group(r'$theme num spec v2', () {
    Map<String, dynamic> themedSpec() => {
      'specVersion': 2,
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
            'props': {
              'data': 'oi',
              'color': {r'$theme': 'brand'},
              'foo': {r'$theme': 'primary'},
            },
          },
        ],
      },
    };

    test('o modo tolerante aceita papel desconhecido e prop fora do catálogo '
        'num nó filho', () {
      final content = parseContentSpec(
        themedSpec(),
        tolerant: true,
      ).toNullable();

      expect(content, isNotNull);
      expect(content!.root!.children.single.properties['color'], {
        r'$theme': 'brand',
      });
    });

    test('o modo estrito recusa o mesmo JSON pelo papel desconhecido', () {
      final error = parseContentSpec(themedSpec()).getLeft().toNullable();

      expect(error, isNotNull);
      expect(
        error!.message,
        r'root.children[0].props.color.$theme: papel de cor "brand" '
        'desconhecido',
      );
    });

    test(r'o modo tolerante também vale para o $theme no safeArea', () {
      final spec = themedSpec()
        ..['safeArea'] = {
          'foo': {r'$theme': 'primary'},
        };

      expect(parseContentSpec(spec).isLeft(), isTrue);
      expect(parseContentSpec(spec, tolerant: true).isRight(), isTrue);
    });
  });
}
