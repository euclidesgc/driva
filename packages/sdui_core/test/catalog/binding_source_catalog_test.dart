import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  BindingSource sourceOf(String id) => bindingSourceFor(id)!;

  group('bindingSourceCatalog', () {
    test('ids são únicos', () {
      final ids = [for (final source in bindingSourceCatalog) source.id];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('toda fonte tem rótulo e ao menos um contexto', () {
      for (final source in bindingSourceCatalog) {
        expect(source.label.trim(), isNotEmpty, reason: source.id);
        expect(source.contexts, isNotEmpty, reason: source.id);
      }
    });

    test('tem exatamente as quatro fontes iniciais', () {
      expect(
        [for (final source in bindingSourceCatalog) source.id],
        unorderedEquals([
          BindingSourceIds.legacy,
          BindingSourceIds.pageParam,
          BindingSourceIds.componentParam,
          BindingSourceIds.actionResult,
        ]),
      );
    });

    test('contextos e tipo de saída de cada fonte', () {
      final expected = <String, (Set<BindingContext>, PropValueType)>{
        BindingSourceIds.legacy: (
          {
            BindingContext.page,
            BindingContext.component,
            BindingContext.action,
          },
          PropValueType.any,
        ),
        BindingSourceIds.pageParam: (
          {BindingContext.page, BindingContext.component},
          PropValueType.declared,
        ),
        BindingSourceIds.componentParam: (
          {BindingContext.component},
          PropValueType.declared,
        ),
        BindingSourceIds.actionResult: (
          {BindingContext.action},
          PropValueType.declared,
        ),
      };

      for (final MapEntry(key: id, value: (contexts, outputType))
          in expected.entries) {
        final source = sourceOf(id);
        expect(source.contexts, contexts, reason: id);
        expect(source.outputType, outputType, reason: id);
      }
    });
  });

  group('bindingSourceFor', () {
    test('acha a fonte pelo id', () {
      expect(bindingSourceFor('pageParam')?.id, BindingSourceIds.pageParam);
    });

    test('devolve null para id desconhecido', () {
      expect(bindingSourceFor('x'), isNull);
    });
  });

  group('bindingSourcesFor', () {
    test('devolve só as fontes disponíveis no contexto', () {
      expect(
        [for (final s in bindingSourcesFor(BindingContext.page)) s.id],
        [BindingSourceIds.legacy, BindingSourceIds.pageParam],
      );
      expect(
        [for (final s in bindingSourcesFor(BindingContext.component)) s.id],
        [
          BindingSourceIds.legacy,
          BindingSourceIds.pageParam,
          BindingSourceIds.componentParam,
        ],
      );
      expect(
        [for (final s in bindingSourcesFor(BindingContext.action)) s.id],
        [BindingSourceIds.legacy, BindingSourceIds.actionResult],
      );
    });

    test('feeding filtra pelas fontes que alimentam o tipo esperado', () {
      const fixedText = BindingSource(
        id: 'fixedText',
        label: 'Texto fixo',
        outputType: PropValueType.text,
        contexts: {BindingContext.page},
      );

      expect(fixedText.feeds(PropValueType.color), isFalse);
      expect(fixedText.feeds(PropValueType.text), isTrue);
      expect(
        bindingSourcesFor(BindingContext.page, feeding: PropValueType.color),
        everyElement(
          predicate<BindingSource>((s) => s.feeds(PropValueType.color)),
        ),
      );
      expect(
        [
          for (final s in bindingSourcesFor(
            BindingContext.page,
            feeding: PropValueType.color,
          ))
            s.id,
        ],
        [BindingSourceIds.legacy, BindingSourceIds.pageParam],
      );
    });
  });

  group('BindingSource', () {
    test('isAvailableIn segue os contextos declarados', () {
      final source = sourceOf(BindingSourceIds.componentParam);
      expect(source.isAvailableIn(BindingContext.component), isTrue);
      expect(source.isAvailableIn(BindingContext.page), isFalse);
    });

    test('igualdade por valor', () {
      const a = BindingSource(
        id: 'a',
        label: 'A',
        outputType: PropValueType.text,
        contexts: {BindingContext.page},
      );
      const b = BindingSource(
        id: 'a',
        label: 'A',
        outputType: PropValueType.text,
        contexts: {BindingContext.page},
      );
      expect(a, b);
    });
  });
}
