import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_group_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _fontSize = PropField(
  key: 'fontSize',
  kind: FieldKind.doubleNum,
  label: 'Tamanho da fonte',
  group: FieldGroups.style,
);

const _color = PropField(
  key: 'color',
  kind: FieldKind.color,
  label: 'Cor',
  group: FieldGroups.style,
);

const _weight = PropField(
  key: 'fontWeight',
  kind: FieldKind.enumeration,
  label: 'Peso da fonte',
  group: FieldGroups.style,
  options: [
    PropOption('w400', label: 'Regular 400'),
    PropOption('w700', label: 'Bold 700'),
  ],
);

const _padding = PropField(
  key: 'padding',
  kind: FieldKind.edgeInsets,
  label: 'Padding',
  group: FieldGroups.spacing,
);

const _enabled = PropField(
  key: 'enabled',
  kind: FieldKind.boolean,
  label: 'Habilitado',
  group: FieldGroups.content,
);

void main() {
  group('resumo do grupo', () {
    test('grupo sem nada definido resume como vazio', () {
      expect(
        PropGroupSummary.of(const [_fontSize, _color], const {}),
        PropGroupSummary.empty,
      );
    });

    test('uma prop definida mostra o valor dela', () {
      expect(
        PropGroupSummary.of(
          const [_fontSize, _color],
          const {'fontSize': 18.0},
        ),
        '18',
      );
    });

    test('mais de uma prop definida mostra a contagem', () {
      expect(
        PropGroupSummary.of(
          const [_fontSize, _color],
          const {
            'fontSize': 18.0,
            'color': '#FFF',
          },
        ),
        '2 definidas',
      );
    });

    test('prop nula não conta como definida', () {
      expect(
        PropGroupSummary.of(
          const [_fontSize, _color],
          const {
            'fontSize': 18.0,
            'color': null,
          },
        ),
        '18',
      );
    });
  });

  group('formatação por tipo', () {
    test('enum mostra o label, não o valor cru', () {
      expect(PropGroupSummary.describe(_weight, 'w700'), 'Bold 700');
    });

    test('enum fora das options cai no valor cru', () {
      expect(PropGroupSummary.describe(_weight, 'w999'), 'w999');
    });

    test('número redondo perde o ".0"', () {
      expect(PropGroupSummary.describe(_fontSize, 18.0), '18');
      expect(PropGroupSummary.describe(_fontSize, 18.5), '18.5');
    });

    test('booleano vira Sim/Não', () {
      expect(PropGroupSummary.describe(_enabled, true), 'Sim');
      expect(PropGroupSummary.describe(_enabled, false), 'Não');
    });

    test('padding uniforme mostra um número só', () {
      expect(PropGroupSummary.describe(_padding, const {'all': 12.0}), '12');
    });

    test('padding por lado mostra os quatro na ordem E·T·D·B', () {
      expect(
        PropGroupSummary.describe(
          _padding,
          const {'left': 8.0, 'top': 12.0, 'right': 8.0, 'bottom': 16.0},
        ),
        '8 · 12 · 8 · 16',
      );
    });

    test('lado ausente conta como zero', () {
      expect(
        PropGroupSummary.describe(_padding, const {'top': 12.0}),
        '0 · 12 · 0 · 0',
      );
    });

    test('valor nulo resume como vazio', () {
      expect(
        PropGroupSummary.describe(_fontSize, null),
        PropGroupSummary.empty,
      );
    });
  });
}
