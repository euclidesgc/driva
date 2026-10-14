import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

const _path = 'root.props';

final WidgetDescriptor _text = descriptorFor('text')!;

const _fixedDescriptor = WidgetDescriptor(
  type: 'fixed',
  label: 'Fixo',
  iconName: 'fixed',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
  fields: [
    PropField(
      key: 'color',
      kind: FieldKind.color,
      label: 'Cor',
      group: FieldGroups.style,
      isBindable: false,
    ),
  ],
);

Map<String, dynamic> _bind(
  String source, {
  String path = 'user.name',
  Object? fallback,
}) => {
  r'$bind': {
    'source': source,
    'path': path,
    'fallback': ?fallback,
  },
};

void main() {
  SpecValidationError? errorOf(
    Map<String, dynamic> props, {
    WidgetDescriptor? descriptor,
    int specVersion = kLatestSpecVersion,
    BindingContext context = BindingContext.page,
  }) => validateNodeProps(
    props,
    descriptor ?? _text,
    path: _path,
    specVersion: specVersion,
    context: context,
  ).getLeft().toNullable();

  void expectAccepted(
    Map<String, dynamic> props, {
    WidgetDescriptor? descriptor,
    int specVersion = kLatestSpecVersion,
  }) {
    expect(
      errorOf(props, descriptor: descriptor, specVersion: specVersion),
      isNull,
    );
  }

  void expectRejected(
    Map<String, dynamic> props,
    String fragment, {
    String key = 'data',
    WidgetDescriptor? descriptor,
    int specVersion = kLatestSpecVersion,
    BindingContext context = BindingContext.page,
  }) {
    final error = errorOf(
      props,
      descriptor: descriptor,
      specVersion: specVersion,
      context: context,
    );
    expect(error, isNotNull, reason: 'esperado Left para $props');
    expect(error!.message, startsWith('$_path.$key'));
    expect(error.message, contains(fragment));
  }

  group('literais e legado não ganham regra nova', () {
    test('literal e {{x}} passam em v1', () {
      expectAccepted({
        'data': 'oi',
        'fontSize': 16,
        'color': '#112233',
      }, specVersion: 1);
      expectAccepted({'data': '{{user.name}}'}, specVersion: 1);
    });

    test('{{x}} em prop obrigatória passa sem fallback', () {
      expectAccepted({'data': '{{x}}'});
    });

    test('{{x}} em prop isBindable: false continua aceito', () {
      expectAccepted({'color': '{{x}}'}, descriptor: _fixedDescriptor);
    });
  });

  group('versão', () {
    test(r'$theme em v1 é recusado citando a specVersion 2', () {
      expectRejected(
        {
          'color': {r'$theme': 'primary'},
        },
        'exige specVersion 2 ou maior (o spec é 1)',
        key: 'color',
        specVersion: 1,
      );
    });

    test(r'$theme em v2 é aceito', () {
      expectAccepted({
        'color': {r'$theme': 'primary'},
      });
    });
  });

  group('forma', () {
    test('erro de forma sobe com o caminho da prop', () {
      expectRejected(
        {
          'data': {r'$theme': ''},
        },
        r'root.props.data.$theme',
      );
    });
  });

  group('isBindable', () {
    test(r'$theme num campo isBindable: false é recusado', () {
      expectRejected(
        {
          'color': {r'$theme': 'primary'},
        },
        'a prop não aceita token do tema nem binding',
        key: 'color',
        descriptor: _fixedDescriptor,
      );
    });
  });

  group('fonte', () {
    test('fonte inexistente é recusada', () {
      expectRejected(
        {'data': _bind('nope', fallback: 'x')},
        r'data.$bind.source: fonte "nope" desconhecida',
      );
    });

    test('componentParam em página é recusado', () {
      expectRejected(
        {'data': _bind('componentParam', fallback: 'x')},
        'fonte "componentParam" não está disponível em página',
      );
    });

    test(r'legacy em $bind é recusado', () {
      expectRejected(
        {'data': _bind('legacy', fallback: 'x')},
        r'data.$bind.source: fonte "legacy" só vale como {{expressão}}',
      );
    });

    test('pageParam com fallback é aceito', () {
      expectAccepted({'data': _bind('pageParam', fallback: 'Visitante')});
    });

    test('componentParam é aceito em componente', () {
      expect(
        errorOf({
          'data': _bind('componentParam', fallback: 'x'),
        }, context: BindingContext.component),
        isNull,
      );
    });
  });

  group('prop obrigatória', () {
    test(r'$bind sem fallback em text.data é recusado', () {
      expectRejected({
        'data': _bind('pageParam'),
      }, 'binding em prop obrigatória exige fallback');
    });

    test(r'$bind sem fallback em prop opcional é aceito', () {
      expect(_text.fieldOf('color')!.isRequired, isFalse);
      expectAccepted({'color': _bind('pageParam')});
    });

    test(r'$theme em prop obrigatória não exige fallback', () {
      expectAccepted({
        'data': {r'$theme': 'headline'},
      });
    });
  });

  group('prop fora do descriptor', () {
    test(r'$theme em v2 é aceito', () {
      expectAccepted({
        'naoExiste': {r'$theme': 'primary'},
      });
    });

    test(r'$bind sem fallback é aceito, mas a fonte é conferida', () {
      expectAccepted({'naoExiste': _bind('pageParam')});
      expectRejected(
        {'naoExiste': _bind('nope')},
        'fonte "nope" desconhecida',
        key: 'naoExiste',
      );
    });

    test('a versão continua sendo conferida', () {
      expectRejected(
        {
          'naoExiste': {r'$theme': 'primary'},
        },
        'specVersion 2',
        key: 'naoExiste',
        specVersion: 1,
      );
    });
  });
}
