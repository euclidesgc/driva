import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  const base = ContentSpec(
    specVersion: 1,
    id: 'c1',
    name: 'Home',
    slug: 'home',
  );
  const titulo = ComponentParam(
    name: 'titulo',
    type: ComponentParamType.text,
    isList: false,
    isRequired: true,
  );
  const aberto = ComponentStateVariable(
    name: 'aberto',
    type: ComponentParamType.boolean,
    isList: false,
    defaultValue: false,
  );

  group('conteúdo de hoje', () {
    test('sem os campos novos é um conteúdo sem params nem state', () {
      expect(base.kind, ContentKind.content);
      expect(base.params, isEmpty);
      expect(base.state, isEmpty);
    });

    test('toJson grava kind content e não tem params nem state', () {
      final json = base.toJson();

      expect(json['kind'], 'content');
      expect(json.containsKey('params'), isFalse);
      expect(json.containsKey('state'), isFalse);
      expect(json, {
        'specVersion': 1,
        'kind': 'content',
        'id': 'c1',
        'name': 'Home',
        'slug': 'home',
      });
    });
  });

  group('componente', () {
    test('serializa kind component e as listas com o toJson de cada item', () {
      final json = base
          .copyWith(
            kind: ContentKind.component,
            params: const [titulo],
            state: const [aberto],
          )
          .toJson();

      expect(json['kind'], 'component');
      expect(json['params'], [titulo.toJson()]);
      expect(json['state'], [aberto.toJson()]);
    });

    test('paramNamed acha o parâmetro declarado e devolve null sem ele', () {
      final component = base.copyWith(params: const [titulo]);

      expect(component.paramNamed('titulo'), titulo);
      expect(component.paramNamed('subtitulo'), isNull);
      expect(base.paramNamed('titulo'), isNull);
    });
  });

  group('copyWith e igualdade', () {
    test('troca kind sem alterar o resto', () {
      final changed = base.copyWith(kind: ContentKind.component);

      expect(changed.kind, ContentKind.component);
      expect(changed.copyWith(kind: ContentKind.content), base);
    });

    test('troca params sem alterar o resto', () {
      final changed = base.copyWith(params: const [titulo]);

      expect(changed.params, [titulo]);
      expect(changed.kind, base.kind);
      expect(changed.state, base.state);
      expect(changed.copyWith(params: const []), base);
    });

    test('troca state sem alterar o resto', () {
      final changed = base.copyWith(state: const [aberto]);

      expect(changed.state, [aberto]);
      expect(changed.params, base.params);
      expect(changed.copyWith(state: const []), base);
    });

    test('specs que diferem só em params não são iguais', () {
      expect(base.copyWith(params: const [titulo]), isNot(base));
    });
  });
}
