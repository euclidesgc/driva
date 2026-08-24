import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/buttons/toggle_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Future<List<Object?>> _pumpEditor(
  WidgetTester tester, {
  required PropField field,
  required Object? value,
}) async {
  final changes = <Object?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: PropFieldEditor(
            field: field,
            value: value,
            onChanged: changes.add,
          ),
        ),
      ),
    ),
  );
  return changes;
}

const _iconGroupField = PropField(
  key: 'crossAxisAlignment',
  kind: FieldKind.enumeration,
  label: 'Alinhamento cruzado',
  group: FieldGroups.layout,
  options: [
    PropOption('start', label: 'Início', iconName: 'crossStart'),
    PropOption('center', label: 'Centro', iconName: 'crossCenter'),
    PropOption('end', label: 'Fim', iconName: 'crossEnd'),
  ],
);

const _padding = PropField(
  key: 'padding',
  kind: FieldKind.edgeInsets,
  label: 'Padding',
  group: FieldGroups.spacing,
);

void main() {
  group('escolha do editor de enum', () {
    testWidgets('ícone em toda option vira grupo de ícones', (tester) async {
      await _pumpEditor(tester, field: _iconGroupField, value: 'center');

      expect(find.byType(EnumIconGroupEditor), findsOneWidget);
      expect(find.byType(EnumEditor), findsNothing);
      expect(find.byType(ToggleButton), findsNWidgets(3));
    });

    testWidgets('sem ícone continua no dropdown, com label legível', (
      tester,
    ) async {
      const semIcone = PropField(
        key: 'overflow',
        kind: FieldKind.enumeration,
        label: 'Overflow',
        group: FieldGroups.content,
        options: [
          PropOption('clip', label: 'Cortar'),
          PropOption('ellipsis', label: 'Reticências'),
        ],
      );

      await _pumpEditor(tester, field: semIcone, value: 'clip');

      expect(find.byType(EnumEditor), findsOneWidget);
      expect(find.byType(EnumIconGroupEditor), findsNothing);
      expect(find.text('Cortar'), findsOneWidget);
    });

    testWidgets('uma option sem ícone derruba o grupo inteiro', (tester) async {
      const misto = PropField(
        key: 'fit',
        kind: FieldKind.enumeration,
        label: 'Ajuste',
        group: FieldGroups.layout,
        options: [
          PropOption('a', label: 'Com ícone', iconName: 'crossStart'),
          PropOption('b', label: 'Sem ícone'),
        ],
      );

      await _pumpEditor(tester, field: misto, value: 'a');

      expect(find.byType(EnumEditor), findsOneWidget);
      expect(find.byType(EnumIconGroupEditor), findsNothing);
    });
  });

  group('EnumIconGroupEditor', () {
    testWidgets('tocar numa option emite o valor dela', (tester) async {
      final changes = await _pumpEditor(
        tester,
        field: _iconGroupField,
        value: 'center',
      );

      await tester.tap(find.byTooltip('Fim'));
      await tester.pump();

      expect(changes, ['end']);
    });

    testWidgets('tocar na option já selecionada limpa o valor', (tester) async {
      final changes = await _pumpEditor(
        tester,
        field: _iconGroupField,
        value: 'center',
      );

      await tester.tap(find.byTooltip('Centro'));
      await tester.pump();

      expect(changes, [null]);
    });

    testWidgets('campo obrigatório não desmarca no segundo toque', (
      tester,
    ) async {
      const obrigatorio = PropField(
        key: 'crossAxisAlignment',
        kind: FieldKind.enumeration,
        label: 'Alinhamento cruzado',
        group: FieldGroups.layout,
        options: [
          PropOption('start', label: 'Início', iconName: 'crossStart'),
          PropOption('center', label: 'Centro', iconName: 'crossCenter'),
        ],
        isRequired: true,
      );

      final changes = await _pumpEditor(
        tester,
        field: obrigatorio,
        value: 'center',
      );

      await tester.tap(find.byTooltip('Centro'));
      await tester.pump();

      expect(changes, ['center']);
    });
  });

  group('NumberEditor', () {
    const comFaixa = PropField(
      key: 'fontSize',
      kind: FieldKind.doubleNum,
      label: 'Tamanho da fonte',
      group: FieldGroups.style,
      min: 8,
      max: 96,
    );

    testWidgets('faixa declarada mostra slider ao lado do campo', (
      tester,
    ) async {
      await _pumpEditor(tester, field: comFaixa, value: 24.0);

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(NumberTextField), findsOneWidget);
    });

    testWidgets('sem faixa, só o campo', (tester) async {
      const semFaixa = PropField(
        key: 'width',
        kind: FieldKind.doubleNum,
        label: 'Largura',
        group: FieldGroups.size,
      );

      await _pumpEditor(tester, field: semFaixa, value: 24.0);

      expect(find.byType(Slider), findsNothing);
      expect(find.byType(NumberTextField), findsOneWidget);
    });

    testWidgets('valor externo fora da faixa é clampado no slider', (
      tester,
    ) async {
      await _pumpEditor(tester, field: comFaixa, value: 500.0);

      expect(tester.widget<Slider>(find.byType(Slider)).value, 96.0);
    });

    testWidgets('inteiro com faixa usa divisions de passo 1', (tester) async {
      const flex = PropField(
        key: 'flex',
        kind: FieldKind.intNum,
        label: 'Flex',
        group: FieldGroups.layout,
        min: 1,
        max: 12,
      );

      await _pumpEditor(tester, field: flex, value: 3);

      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 11);
    });

    testWidgets('valor abaixo do mínimo diz na tela para onde foi ajustado', (
      tester,
    ) async {
      await _pumpEditor(tester, field: comFaixa, value: 24.0);

      await tester.enterText(find.byType(TextField), '2');
      await tester.pumpAndSettle();

      expect(find.text('Ajustado para o mínimo (8)'), findsOneWidget);
    });

    testWidgets('texto não numérico mostra o erro na tela', (tester) async {
      await _pumpEditor(tester, field: comFaixa, value: 24.0);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      expect(find.text('Valor inválido'), findsOneWidget);
      expect(find.text('Ajustado para o mínimo (8)'), findsNothing);
    });

    testWidgets('valor com muitas casas é exibido com duas', (tester) async {
      const semFaixa = PropField(
        key: 'opacity',
        kind: FieldKind.doubleNum,
        label: 'Opacidade',
        group: FieldGroups.style,
      );

      await _pumpEditor(tester, field: semFaixa, value: 12.3456789012);

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12.35',
      );
    });

    testWidgets('valor inteiro é exibido sem casas decimais', (tester) async {
      const semFaixa = PropField(
        key: 'opacity',
        kind: FieldKind.doubleNum,
        label: 'Opacidade',
        group: FieldGroups.style,
      );

      await _pumpEditor(tester, field: semFaixa, value: 12.0);

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12',
      );
    });
  });

  group('PropResetButton', () {
    const opcional = PropField(
      key: 'width',
      kind: FieldKind.doubleNum,
      label: 'Largura',
      group: FieldGroups.size,
    );

    testWidgets('some quando a propriedade não tem valor', (tester) async {
      await _pumpEditor(tester, field: opcional, value: null);

      expect(find.byType(PropResetButton), findsNothing);
    });

    testWidgets('remove a chave do spec', (tester) async {
      final changes = await _pumpEditor(tester, field: opcional, value: 120.0);

      expect(find.byType(PropResetButton), findsOneWidget);
      await tester.tap(find.byType(PropResetButton));
      await tester.pump();

      expect(changes, [null]);
    });

    testWidgets('campo obrigatório não oferece o reset', (tester) async {
      const obrigatorio = PropField(
        key: 'data',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
        isRequired: true,
      );

      await _pumpEditor(tester, field: obrigatorio, value: 'Oi');

      expect(find.byType(PropResetButton), findsNothing);
    });

    testWidgets('botão de canto fica encostado na margem direita', (
      tester,
    ) async {
      await _pumpEditor(tester, field: opcional, value: 120.0);

      final painel = tester.getRect(find.byType(PropFieldEditor));
      final botao = tester.getRect(find.byType(PropResetButton));

      expect(painel.right - botao.right, lessThan(16.0));
    });
  });

  group('EdgeInsetsEditor', () {
    testWidgets('valor com "all" abre no modo uniforme', (tester) async {
      await _pumpEditor(tester, field: _padding, value: const {'all': 12.0});

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('T'), findsNothing);
    });

    testWidgets('lados diferentes abrem no modo individual', (tester) async {
      await _pumpEditor(
        tester,
        field: _padding,
        value: const {'left': 8.0, 'top': 12.0, 'right': 8.0, 'bottom': 16.0},
      );

      expect(find.text('Todos'), findsNothing);
      expect(find.text('T'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('lados iguais abrem no modo uniforme', (tester) async {
      await _pumpEditor(
        tester,
        field: _padding,
        value: const {'left': 8.0, 'top': 8.0, 'right': 8.0, 'bottom': 8.0},
      );

      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('uniforme para individual espalha o valor nos quatro lados', (
      tester,
    ) async {
      final changes = await _pumpEditor(
        tester,
        field: _padding,
        value: const {'all': 12.0},
      );

      await tester.tap(find.byTooltip('Lado a lado'));
      await tester.pump();

      expect(changes, [
        {'left': 12.0, 'top': 12.0, 'right': 12.0, 'bottom': 12.0},
      ]);
    });

    testWidgets('individual para uniforme colapsa em "all"', (tester) async {
      final changes = await _pumpEditor(
        tester,
        field: _padding,
        value: const {'left': 8.0, 'top': 8.0, 'right': 8.0, 'bottom': 8.0},
      );

      await tester.tap(find.byTooltip('Lado a lado'));
      await tester.pump();
      await tester.tap(find.byTooltip('Todos os lados'));
      await tester.pump();

      expect(changes.last, {'all': 8.0});
    });
  });
}
