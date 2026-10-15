import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('PropOption', () {
    test('displayLabel cai no value quando não há label', () {
      expect(const PropOption('start').displayLabel, 'start');
      expect(const PropOption('start', label: 'Início').displayLabel, 'Início');
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

    test('igualdade cobre visibleWhen', () {
      const semCondicao = PropField(
        key: 'hoverColor',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      );
      const comCondicao = PropField(
        key: 'hoverColor',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
        visibleWhen: PropEquals('hoverEnabled', true),
      );
      const outraCondicao = PropField(
        key: 'hoverColor',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
        visibleWhen: PropEquals('hoverEnabled', false),
      );

      expect(semCondicao, isNot(comCondicao));
      expect(comCondicao, isNot(outraCondicao));
      expect(
        comCondicao,
        const PropField(
          key: 'hoverColor',
          kind: FieldKind.color,
          label: 'Cor',
          group: FieldGroups.style,
          visibleWhen: PropEquals('hoverEnabled', true),
        ),
      );
    });

    test('valueType deriva do kind por padrão', () {
      const field = PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      );

      expect(field.declaredValueType, isNull);
      expect(field.valueType, PropValueType.color);
    });

    test('declaredValueType sobrescreve o tipo do kind', () {
      const field = PropField(
        key: 'count',
        kind: FieldKind.string,
        label: 'Quantidade',
        group: FieldGroups.content,
        declaredValueType: PropValueType.integer,
      );

      expect(field.valueType, PropValueType.integer);
    });

    test('igualdade cobre declaredValueType', () {
      const derivado = PropField(
        key: 'count',
        kind: FieldKind.string,
        label: 'Quantidade',
        group: FieldGroups.content,
      );
      const declarado = PropField(
        key: 'count',
        kind: FieldKind.string,
        label: 'Quantidade',
        group: FieldGroups.content,
        declaredValueType: PropValueType.integer,
      );

      expect(derivado, isNot(declarado));
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

    test('todo campo declara o tipo esperado, sem tipo de saída de fonte', () {
      final descriptors = [...widgetCatalog.values, safeAreaDescriptor];
      for (final descriptor in descriptors) {
        for (final field in descriptor.fields) {
          final reason = '${descriptor.type}.${field.key}';
          expect(
            field.valueType,
            field.declaredValueType ?? field.kind.valueType,
            reason: reason,
          );
          expect(
            field.valueType,
            isNot(anyOf(PropValueType.any, PropValueType.declared)),
            reason: reason,
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
