import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

typedef _Param = ({
  String key,
  FieldKind kind,
  bool isRequired,
  Object? defaultValue,
});

void main() {
  const pageAndComponent = {BindingContext.page, BindingContext.component};

  group('actionCatalog', () {
    test('tem as sete ações da primeira leva, nesta ordem', () {
      expect(actionCatalog.map((a) => a.type), [
        'navigate',
        'navigateBack',
        'launchUrl',
        'showSnackBar',
        'copyToClipboard',
        'wait',
        'apiCall',
      ]);
    });

    test(
      'cada ação tem categoria, rótulo, contextos e parâmetros da tabela',
      () {
        const expected =
            <String, (String category, String label, List<_Param> params)>{
              'navigate': (
                ActionCategories.navigation,
                'Navegar para conteúdo',
                [
                  (
                    key: 'slug',
                    kind: FieldKind.string,
                    isRequired: true,
                    defaultValue: null,
                  ),
                ],
              ),
              'navigateBack': (ActionCategories.navigation, 'Voltar', []),
              'launchUrl': (
                ActionCategories.navigation,
                'Abrir link',
                [
                  (
                    key: 'url',
                    kind: FieldKind.string,
                    isRequired: true,
                    defaultValue: null,
                  ),
                ],
              ),
              'showSnackBar': (
                ActionCategories.alerts,
                'Mostrar aviso',
                [
                  (
                    key: 'message',
                    kind: FieldKind.string,
                    isRequired: true,
                    defaultValue: null,
                  ),
                  (
                    key: 'durationMs',
                    kind: FieldKind.intNum,
                    isRequired: false,
                    defaultValue: 4000,
                  ),
                  (
                    key: 'backgroundColor',
                    kind: FieldKind.color,
                    isRequired: false,
                    defaultValue: null,
                  ),
                ],
              ),
              'copyToClipboard': (
                ActionCategories.utilities,
                'Copiar texto',
                [
                  (
                    key: 'text',
                    kind: FieldKind.string,
                    isRequired: true,
                    defaultValue: null,
                  ),
                ],
              ),
              'wait': (
                ActionCategories.utilities,
                'Aguardar',
                [
                  (
                    key: 'durationMs',
                    kind: FieldKind.intNum,
                    isRequired: true,
                    defaultValue: null,
                  ),
                ],
              ),
              'apiCall': (
                ActionCategories.backend,
                'Chamar API',
                [
                  (
                    key: 'url',
                    kind: FieldKind.string,
                    isRequired: true,
                    defaultValue: null,
                  ),
                  (
                    key: 'method',
                    kind: FieldKind.enumeration,
                    isRequired: false,
                    defaultValue: 'GET',
                  ),
                ],
              ),
            };

        expect(
          actionCatalog.map((a) => a.type),
          unorderedEquals(expected.keys),
        );
        for (final action in actionCatalog) {
          final (category, label, params) = expected[action.type]!;
          expect(action.category, category, reason: action.type);
          expect(action.label, label, reason: action.type);
          expect(action.contexts, pageAndComponent, reason: action.type);
          expect(
            [
              for (final p in action.params)
                (
                  key: p.key,
                  kind: p.kind,
                  isRequired: p.isRequired,
                  defaultValue: p.defaultValue,
                ),
            ],
            params,
            reason: action.type,
          );
        }
      },
    );

    test('apiCall.method é um enum fixo com os cinco métodos HTTP', () {
      final method = actionFor('apiCall')!.paramOf('method')!;

      expect(method.enumValues, ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']);
      expect(method.isBindable, isFalse);
    });

    test('durações aceitam só valor não negativo no editor', () {
      expect(actionFor('showSnackBar')!.paramOf('durationMs')!.min, 0);
      expect(actionFor('wait')!.paramOf('durationMs')!.min, 0);
    });

    test('backgroundColor é do grupo Estilo e os demais de Conteúdo', () {
      for (final action in actionCatalog) {
        for (final param in action.params) {
          expect(
            param.group,
            param.key == 'backgroundColor'
                ? FieldGroups.style
                : FieldGroups.content,
            reason: '${action.type}.${param.key}',
          );
        }
      }
    });

    test('integridade: type único, textos preenchidos, params coerentes', () {
      final types = <String>{};
      for (final action in actionCatalog) {
        expect(types.add(action.type), isTrue, reason: 'repetido');
        expect(action.label, isNotEmpty, reason: action.type);
        expect(action.category, isNotEmpty, reason: action.type);
        expect(
          ActionCategories.inPickerOrder,
          contains(action.category),
          reason: action.type,
        );
        final keys = <String>{};
        for (final param in action.params) {
          expect(
            keys.add(param.key),
            isTrue,
            reason: '${action.type}.${param.key} repetido',
          );
          expect(
            FieldKind.values,
            contains(param.kind),
            reason: '${action.type}.${param.key}',
          );
        }
      }
    });
  });

  group('ActionCategories', () {
    test('ordem do seletor', () {
      expect(ActionCategories.inPickerOrder, [
        'Navegação',
        'Alertas',
        'Utilitários',
        'Backend',
      ]);
    });
  });

  group('ActionDescriptor', () {
    test('requiredParams lista só os obrigatórios, na ordem', () {
      expect(
        actionFor('showSnackBar')!.requiredParams.map((p) => p.key),
        ['message'],
      );
      expect(actionFor('navigateBack')!.requiredParams, isEmpty);
    });

    test('paramOf devolve null para chave desconhecida', () {
      expect(actionFor('navigate')!.paramOf('to'), isNull);
    });
  });

  group('actionFor', () {
    test('acha a ação pelo type', () {
      expect(actionFor('navigate'), actionCatalog.first);
    });

    test('devolve null fora do catálogo', () {
      expect(actionFor('abrirPorta'), isNull);
    });
  });

  group('actionsFor', () {
    test('em página, as sete ações na ordem das categorias', () {
      final result = actionsFor(BindingContext.page);

      expect(result, hasLength(7));
      expect(
        result.map((a) => ActionCategories.inPickerOrder.indexOf(a.category)),
        orderedEquals([0, 0, 0, 1, 2, 2, 3]),
      );
      expect(result.map((a) => a.type), [
        'navigate',
        'navigateBack',
        'launchUrl',
        'showSnackBar',
        'copyToClipboard',
        'wait',
        'apiCall',
      ]);
    });

    test('omite a ação que não está disponível no contexto', () {
      const onlyInComponent = ActionDescriptor(
        type: 'executeCallback',
        label: 'Executar callback',
        iconName: 'x',
        category: ActionCategories.utilities,
        contexts: {BindingContext.component},
      );
      const everywhere = ActionDescriptor(
        type: 'wait',
        label: 'Aguardar',
        iconName: 'x',
        category: ActionCategories.utilities,
      );
      const actions = [onlyInComponent, everywhere];

      expect(actionsFor(BindingContext.page, actions: actions), [everywhere]);
      expect(actionsFor(BindingContext.component, actions: actions), actions);
    });

    test('ordena por categoria antes da ordem do catálogo', () {
      const backend = ActionDescriptor(
        type: 'b',
        label: 'B',
        iconName: 'x',
        category: ActionCategories.backend,
      );
      const navigation = ActionDescriptor(
        type: 'n',
        label: 'N',
        iconName: 'x',
        category: ActionCategories.navigation,
      );

      expect(
        actionsFor(BindingContext.page, actions: const [backend, navigation]),
        [navigation, backend],
      );
    });
  });
}
