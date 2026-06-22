import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/src/binding/resolve_bindings.dart';

void main() {
  test('substitui {{chave}} por valor de data', () {
    final out = resolveBindings(
      {
        'type': 'text',
        'props': {'data': '{{label}}'},
      },
      data: {'label': 'Comprar'},
    );
    expect((out['props'] as Map)['data'], 'Comprar');
  });

  test('resolve token de design system nas cores', () {
    final out = resolveBindings(
      {
        'type': 'container',
        'props': {'color': r'$primary'},
      },
      tokens: {'primary': '#1565C0'},
    );
    expect((out['props'] as Map)['color'], '#1565C0');
  });

  test('resolve em profundidade (style.color e args de ação)', () {
    final out = resolveBindings(
      {
        'type': 'text',
        'props': {
          'style': {'color': '{{c}}'},
        },
        'events': {
          'onTap': [
            {
              'type': 'navigate',
              'params': {
                'args': {'id': '{{pid}}'},
              },
            },
          ],
        },
      },
      data: {'c': '#FFFFFF', 'pid': '42'},
    );
    expect(((out['props'] as Map)['style'] as Map)['color'], '#FFFFFF');
    final args = ((((out['events'] as Map)['onTap'] as List).first
            as Map)['params'] as Map)['args'] as Map;
    expect(args['id'], '42');
  });

  test('binding com espaços e pontos', () {
    final out = resolveBindings(
      {
        'type': 'text',
        'props': {'data': '{{ user.name }}'},
      },
      data: {'user.name': 'Ana'},
    );
    expect((out['props'] as Map)['data'], 'Ana');
  });

  test('binding não resolvido mantém o literal', () {
    final out = resolveBindings(
      {
        'type': 'text',
        'props': {'data': '{{x}}'},
      },
      data: const {},
    );
    expect((out['props'] as Map)['data'], '{{x}}');
  });
}
