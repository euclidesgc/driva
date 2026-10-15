import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

SduiNode _node(String type, Map<String, dynamic> props) =>
    SduiNode(id: 'n', type: type, properties: props);

Map<String, dynamic> _bind({Object? fallback, Object? preview}) => {
  r'$bind': {
    'source': BindingSourceIds.pageParam,
    'path': 'nome',
    'fallback': ?fallback,
    'preview': ?preview,
  },
};

void main() {
  group('resolveBoundProps', () {
    test('modo fallback usa o fallback', () {
      final node = _node('text', {
        'text': _bind(fallback: 'Visitante', preview: 'Maria'),
      });

      expect(resolveBoundProps(node).properties['text'], 'Visitante');
    });

    test('modo preview usa o preview', () {
      final node = _node('text', {
        'text': _bind(fallback: 'Visitante', preview: 'Maria'),
      });

      final resolved = resolveBoundProps(
        node,
        display: BoundValueDisplay.preview,
      );

      expect(resolved.properties['text'], 'Maria');
    });

    test('modo preview sem preview cai no fallback', () {
      final node = _node('text', {'text': _bind(fallback: 'Visitante')});

      final resolved = resolveBoundProps(
        node,
        display: BoundValueDisplay.preview,
      );

      expect(resolved.properties['text'], 'Visitante');
    });

    test(r'$bind sem fallback nem preview remove a chave', () {
      final node = _node('text', {'text': _bind(), 'color': '#FF0000'});

      final resolved = resolveBoundProps(node);

      expect(resolved.properties, {'color': '#FF0000'});
    });

    test(r'$bind malformado remove a chave sem lançar', () {
      final node = _node('text', {
        'text': {
          r'$bind': {'source': 'pageParam'},
        },
        'color': '#FF0000',
      });

      final resolved = resolveBoundProps(node);

      expect(resolved.properties, {'color': '#FF0000'});
    });

    test('{{x}} em prop booleana é removido', () {
      final node = _node('checkbox', {'value': '{{aceito}}'});

      expect(resolveBoundProps(node).properties.containsKey('value'), isFalse);
    });

    test('{{x}} em prop de texto é mantido', () {
      final node = _node('text', {'text': '{{nome}}'});

      expect(resolveBoundProps(node).properties['text'], '{{nome}}');
    });

    test(r'$theme é mantido como veio', () {
      final node = _node('text', {
        'color': {r'$theme': 'primary'},
      });

      expect(resolveBoundProps(node).properties['color'], {
        r'$theme': 'primary',
      });
    });

    test('nó sem nada a resolver volta idêntico', () {
      final node = _node('text', {
        'text': 'Olá',
        'color': {r'$theme': 'primary'},
      });

      expect(identical(resolveBoundProps(node), node), isTrue);
    });

    test('não mexe nos filhos', () {
      final child = _node('text', {'text': _bind(fallback: 'x')});
      final parent = SduiNode(id: 'p', type: 'column', children: [child]);

      expect(identical(resolveBoundProps(parent), parent), isTrue);
    });
  });
}
