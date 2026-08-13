import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('PropOption', () {
    test('displayLabel cai no value quando não há label', () {
      expect(const PropOption('start').displayLabel, 'start');
      expect(
        const PropOption('start', label: 'Início').displayLabel,
        'Início',
      );
    });
  });

  group('PropField', () {
    test('enumValues deriva de options preservando a ordem', () {
      const field = PropField(
        key: 'mainAxisSize',
        kind: FieldKind.enumeration,
        label: 'Tamanho do eixo',
        group: FieldGroups.layout,
        options: [
          PropOption('max', label: 'Expandir', iconName: 'sizeMax'),
          PropOption('min', label: 'Encolher', iconName: 'sizeMin'),
        ],
      );

      expect(field.enumValues, ['max', 'min']);
    });

    test('hasRange exige min e max juntos', () {
      const semFaixa = PropField(
        key: 'width',
        kind: FieldKind.doubleNum,
        label: 'Largura',
        group: FieldGroups.size,
        min: 0,
      );
      const comFaixa = PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
        min: 8,
        max: 96,
      );

      expect(semFaixa.hasRange, isFalse);
      expect(comFaixa.hasRange, isTrue);
    });

    test('é editável por binding por padrão', () {
      const field = PropField(
        key: 'data',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
      );

      expect(field.isBindable, isTrue);
      expect(field.isAdvanced, isFalse);
    });

    test('igualdade cobre os metadados novos', () {
      const base = PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
        min: 8,
        max: 96,
      );
      const outroMax = PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
        min: 8,
        max: 48,
      );

      expect(base, isNot(outroMax));
    });
  });

  group('catálogo', () {
    test('toda option de enum tem label em pt-BR', () {
      for (final descriptor in widgetCatalog.values) {
        for (final field in descriptor.fields) {
          if (field.kind != FieldKind.enumeration) continue;
          for (final option in field.options) {
            expect(
              option.label,
              isNotNull,
              reason:
                  '${descriptor.type}.${field.key}: '
                  'option "${option.value}" sem label',
            );
          }
        }
      }
    });

    test('faixa numérica declarada é coerente (min < max)', () {
      for (final descriptor in widgetCatalog.values) {
        for (final field in descriptor.fields) {
          if (!field.hasRange) continue;
          expect(
            field.min,
            lessThan(field.max!),
            reason: '${descriptor.type}.${field.key}',
          );
        }
      }
    });

    test('default numérico respeita a faixa declarada', () {
      for (final descriptor in widgetCatalog.values) {
        for (final field in descriptor.fields) {
          final defaultValue = field.defaultValue;
          if (!field.hasRange || defaultValue is! num) continue;
          expect(
            defaultValue,
            inInclusiveRange(field.min!, field.max!),
            reason: '${descriptor.type}.${field.key}',
          );
        }
      }
    });

    test('default de enum é um dos valores declarados', () {
      for (final descriptor in widgetCatalog.values) {
        for (final field in descriptor.fields) {
          if (field.kind != FieldKind.enumeration) continue;
          final defaultValue = field.defaultValue;
          if (defaultValue == null) continue;
          expect(
            field.enumValues,
            contains(defaultValue),
            reason: '${descriptor.type}.${field.key}',
          );
        }
      }
    });
  });
}
