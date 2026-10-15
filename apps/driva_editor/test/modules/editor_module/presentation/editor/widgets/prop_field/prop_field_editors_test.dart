import 'dart:ui' show Tristate;

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
            onBind: (_) {},
            onUnbind: () {},
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
  min: 0,
  max: 200,
  step: 1,
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

  group('Box Fit da imagem', () {
    final fitField = descriptorFor(
      'image',
    )!.fields.firstWhere((f) => f.key == 'fit');
    const labels = [
      'Preencher',
      'Conter',
      'Cobrir',
      'Ajustar largura',
      'Ajustar altura',
      'Nenhum',
      'Reduzir',
    ];

    testWidgets('renderiza 7 botões com rótulo pt-BR', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpEditor(tester, field: fitField, value: 'contain');

      expect(find.byType(EnumIconGroupEditor), findsOneWidget);
      expect(find.byType(ToggleButton), findsNWidgets(7));
      for (final label in labels) {
        expect(
          find.bySemanticsLabel(label),
          findsOneWidget,
          reason: label,
        );
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.getSemanticsData().flagsCollection.isButton, true);
        expect(
          node.getSemanticsData().flagsCollection.isSelected,
          label == 'Conter' ? Tristate.isTrue : Tristate.isFalse,
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('botão do valor atual vem selecionado', (tester) async {
      await _pumpEditor(tester, field: fitField, value: 'contain');

      final selected = tester
          .widgetList<ToggleButton>(find.byType(ToggleButton))
          .where((b) => b.selected)
          .toList();
      expect(selected, hasLength(1));
      expect(selected.single.tooltip, 'Conter');
    });

    testWidgets('tocar em Cobrir emite cover', (tester) async {
      final changes = await _pumpEditor(
        tester,
        field: fitField,
        value: 'contain',
      );

      await tester.tap(find.byTooltip('Cobrir'));
      await tester.pump();

      expect(changes, ['cover']);
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
    const iguais = {'left': 8.0, 'top': 8.0, 'right': 8.0, 'bottom': 8.0};
    const diferentes = {'left': 8.0, 'top': 4.0, 'right': 8.0, 'bottom': 4.0};

    testWidgets('valor com "all" abre no modo uniforme, sem rótulo de lado', (
      tester,
    ) async {
      await _pumpEditor(tester, field: _padding, value: const {'all': 12.0});

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('T'), findsNothing);
    });

    testWidgets('lados iguais abrem em uniforme com 1 slider e 1 campo', (
      tester,
    ) async {
      await _pumpEditor(tester, field: _padding, value: iguais);

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 8.0);
    });

    testWidgets('lados diferentes abrem por lado: 4 campos e nenhum slider', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        field: _padding,
        value: const {'left': 8.0, 'top': 12.0, 'right': 8.0, 'bottom': 16.0},
      );

      expect(find.byType(Slider), findsNothing);
      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('T'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('arrastar o slider grava {all: X}', (tester) async {
      final changes = await _pumpEditor(
        tester,
        field: _padding,
        value: const {'all': 8.0},
      );

      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pump();

      expect(changes, isNotEmpty);
      final gravado = changes.last! as Map;
      expect(gravado.keys, ['all']);
      expect(gravado['all'], greaterThan(8.0));
    });

    testWidgets('digitar acima do máximo grava 200 e avisa na tela', (
      tester,
    ) async {
      final changes = await _pumpEditor(
        tester,
        field: _padding,
        value: const {'all': 8.0},
      );

      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      expect(changes.last, {'all': 200.0});
      expect(find.text('Ajustado para o máximo (200)'), findsOneWidget);
    });

    testWidgets('lados diferentes: trocar para uniforme não grava nada', (
      tester,
    ) async {
      final changes = await _pumpEditor(
        tester,
        field: _padding,
        value: diferentes,
      );

      await tester.tap(find.byTooltip('Todos os lados'));
      await tester.pump();

      expect(changes, isEmpty);
      expect(find.byType(Slider), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
    });

    testWidgets(
      '{all: 8}: trocar para por lado mostra 8 nos 4 lados sem gravar',
      (
        tester,
      ) async {
        final changes = await _pumpEditor(
          tester,
          field: _padding,
          value: const {'all': 8.0},
        );

        await tester.tap(find.byTooltip('Lado a lado'));
        await tester.pump();

        expect(changes, isEmpty);
        expect(find.byType(Slider), findsNothing);
        final campos = tester.widgetList<TextField>(find.byType(TextField));
        expect(campos.map((c) => c.controller?.text), ['8', '8', '8', '8']);
      },
    );
  });

  group('NumberEditor com default não numérico', () {
    testWidgets('o default em mapa não derruba o slider', (tester) async {
      const field = PropField(
        key: 'padding',
        kind: FieldKind.edgeInsets,
        label: 'Padding',
        group: FieldGroups.spacing,
        min: 0,
        max: 200,
        defaultValue: {'all': 8.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: NumberEditor(
                field: field,
                value: null,
                onChanged: (_) {},
                isInt: false,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 0.0);
    });
  });
}
