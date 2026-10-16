import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_steps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  ActionDescriptor action(String type) => actionFor(type)!;

  group('initialStep', () {
    test('showSnackBar nasce com a mensagem vazia e a duração padrão', () {
      expect(initialStep(action('showSnackBar')), {
        'action': 'showSnackBar',
        'params': {'message': '', 'durationMs': 4000},
      });
    });

    test('toda ação da página nasce salvável no parse estrito', () {
      for (final candidate in actionsFor(BindingContext.page)) {
        final parsed = parseNodeEvents(
          {
            'onTap': [initialStep(candidate)],
          },
          descriptorFor('container')!,
          path: 'root.events',
          specVersion: kLatestSpecVersion,
          tolerant: false,
        );
        expect(
          parsed,
          isA<Right<SpecValidationError, Object?>>(),
          reason: '${candidate.type}: $parsed',
        );
      }
    });
  });

  group('neutralValueFor', () {
    test('opcional sem default fica ausente', () {
      final color = action('showSnackBar').paramOf('backgroundColor')!;
      expect(neutralValueFor(color), isNull);
    });

    test('obrigatório sem default ganha o neutro do tipo', () {
      expect(neutralValueFor(action('wait').paramOf('durationMs')!), 0);
      expect(neutralValueFor(action('navigate').paramOf('slug')!), '');
    });

    test('enumeração obrigatória sem default ganha a primeira opção', () {
      const field = PropField(
        key: 'k',
        kind: FieldKind.enumeration,
        label: 'K',
        group: FieldGroups.content,
        isRequired: true,
        options: [PropOption('a'), PropOption('b')],
      );
      expect(neutralValueFor(field), 'a');
    });
  });

  group('withFirstStepParam', () {
    final steps = <Map<String, dynamic>>[
      {
        'type': 'showSnackBar',
        'params': {'message': 'Oi', 'durationMs': 1000},
      },
      {
        'action': 'wait',
        'params': {'durationMs': 500},
      },
      {'action': 'navigateBack', 'params': <String, dynamic>{}},
    ];

    test('altera só o params do primeiro passo e mantém a chave type', () {
      final result = withFirstStepParam(steps, 'message', 'Olá');
      expect(result.first, {
        'type': 'showSnackBar',
        'params': {'message': 'Olá', 'durationMs': 1000},
      });
      expect(result.skip(1), steps.skip(1));
      expect(steps.first['params'], {'message': 'Oi', 'durationMs': 1000});
    });

    test('null remove a chave do params', () {
      final result = withFirstStepParam(steps, 'durationMs', null);
      expect(result.first['params'], {'message': 'Oi'});
      expect(result.skip(1), steps.skip(1));
    });
  });

  test('withFirstStepAction troca a ação e descarta os parâmetros antigos', () {
    final steps = <Map<String, dynamic>>[
      {
        'action': 'showSnackBar',
        'params': {'message': 'Oi'},
      },
      {'action': 'navigateBack', 'params': <String, dynamic>{}},
    ];
    final result = withFirstStepAction(steps, action('wait'));
    expect(result, [
      {
        'action': 'wait',
        'params': {'durationMs': 0},
      },
      steps[1],
    ]);
  });

  test('boundParamValue guarda o literal por baixo do binding', () {
    const binding = BoundPropValue(
      source: BindingSourceIds.pageParam,
      path: 'nome',
    );
    final stored = boundParamValue('Olá', binding);
    expect(literalUnder(stored), 'Olá');
  });

  group('gatilhos', () {
    test('text não oferece onChanged; switch oferece', () {
      const text = SduiNode(id: 't', type: 'text');
      const toggle = SduiNode(id: 's', type: 'switch');
      expect(
        availableTriggers(text, descriptorFor('text')!),
        isNot(contains(EventTrigger.onChanged)),
      );
      expect(
        availableTriggers(toggle, descriptorFor('switch')!),
        contains(EventTrigger.onChanged),
      );
    });

    test('container com onTap configurado não o oferece de novo', () {
      const container = SduiNode(
        id: 'c',
        type: 'container',
        events: {
          'onTap': [
            {'action': 'navigateBack'},
          ],
        },
      );
      final descriptor = descriptorFor('container')!;
      expect(
        availableTriggers(container, descriptor),
        isNot(contains(EventTrigger.onTap)),
      );
      expect(configuredTriggers(container, descriptor), [EventTrigger.onTap]);
    });
  });

  group('stepsOf', () {
    test('gatilho ausente, valor que não é lista e lista vazia dão []', () {
      const absent = SduiNode(id: 'a', type: 'container');
      const notList = SduiNode(
        id: 'b',
        type: 'container',
        events: {'onTap': 'navigateBack'},
      );
      const empty = SduiNode(
        id: 'c',
        type: 'container',
        events: {'onTap': <Object>[]},
      );
      for (final node in [absent, notList, empty]) {
        expect(stepsOf(node, EventTrigger.onTap), isEmpty, reason: node.id);
      }
    });
  });

  test('actionTypeOf lê action e, no passo legado, type', () {
    expect(actionTypeOf({'action': 'wait'}), 'wait');
    expect(actionTypeOf({'type': 'wait'}), 'wait');
    expect(actionTypeOf({}), isNull);
  });
}
