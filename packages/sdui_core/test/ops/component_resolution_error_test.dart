import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

String _kindOf(ComponentResolutionError error) => switch (error) {
  ComponentNotFound() => 'notFound',
  MissingRequiredArg() => 'missingArg',
  ArgTypeMismatch() => 'typeMismatch',
  ComponentCycle() => 'cycle',
  ComponentDepthExceeded() => 'depth',
};

void main() {
  const notFound = ComponentNotFound(instanceId: 'inst1', componentId: 'c9');
  const missingArg = MissingRequiredArg(
    instanceId: 'inst1',
    componentName: 'Card',
    paramName: 'titulo',
  );
  const typeMismatch = ArgTypeMismatch(
    instanceId: 'inst1',
    componentName: 'Card',
    paramName: 'precos',
    expected: ComponentParamType.integer,
    expectedList: true,
  );
  const cycle = ComponentCycle(instanceId: 'inst1', chain: ['A', 'B', 'A']);
  const depth = ComponentDepthExceeded(
    instanceId: 'inst1/a/b/c/d/e',
    limit: 5,
    chain: ['A', 'B', 'C', 'D', 'E', 'F'],
  );

  group('ComponentResolutionError', () {
    test('o switch sobre a família cobre os 5 casos', () {
      expect(
        [notFound, missingArg, typeMismatch, cycle, depth].map(_kindOf),
        ['notFound', 'missingArg', 'typeMismatch', 'cycle', 'depth'],
      );
    });

    test('ComponentNotFound cita o componentId', () {
      expect(notFound.message, 'Componente "c9" não encontrado');
    });

    test('MissingRequiredArg cita o componente e o parâmetro', () {
      expect(
        missingArg.message,
        'Componente "Card": o parâmetro obrigatório "titulo" não recebeu valor',
      );
    });

    test('ArgTypeMismatch cita o tipo esperado pelo label e a lista', () {
      expect(typeMismatch.message, contains('"precos"'));
      expect(typeMismatch.message, contains('lista de número inteiro'));
    });

    test('ArgTypeMismatch sem lista cita só o label', () {
      const single = ArgTypeMismatch(
        instanceId: 'inst1',
        componentName: 'Card',
        paramName: 'titulo',
        expected: ComponentParamType.text,
        expectedList: false,
      );

      expect(single.message, contains('(texto)'));
      expect(single.message, isNot(contains('lista')));
    });

    test('ComponentCycle mostra a cadeia com →', () {
      expect(cycle.message, 'Ciclo de componentes: A → B → A');
    });

    test('ComponentDepthExceeded cita o limite e a cadeia', () {
      expect(
        depth.message,
        'Componentes aninhados além do limite de 5: A → B → C → D → E → F',
      );
    });

    test('erros com os mesmos dados são iguais', () {
      expect(
        const ComponentNotFound(instanceId: 'inst1', componentId: 'c9'),
        notFound,
      );
      expect(
        const ComponentCycle(instanceId: 'inst1', chain: ['A', 'B', 'A']),
        cycle,
      );
    });

    test('mudar o instanceId torna os erros diferentes', () {
      expect(
        const ComponentNotFound(instanceId: 'inst2', componentId: 'c9'),
        isNot(notFound),
      );
      expect(
        const MissingRequiredArg(
          instanceId: 'inst2',
          componentName: 'Card',
          paramName: 'titulo',
        ),
        isNot(missingArg),
      );
    });
  });
}
