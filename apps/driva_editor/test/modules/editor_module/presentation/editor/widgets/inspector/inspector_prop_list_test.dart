import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _descriptor = WidgetDescriptor(
  type: 'text',
  label: 'Text',
  iconName: 'text',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
  fields: [
    PropField(
      key: 'data',
      kind: FieldKind.string,
      label: 'Texto',
      group: FieldGroups.content,
    ),
    PropField(
      key: 'maxLines',
      kind: FieldKind.intNum,
      label: 'Máximo de linhas',
      group: FieldGroups.content,
    ),
    PropField(
      key: 'fontSize',
      kind: FieldKind.doubleNum,
      label: 'Tamanho da fonte',
      group: FieldGroups.style,
    ),
  ],
);

const _otherDescriptor = WidgetDescriptor(
  type: 'button',
  label: 'Button',
  iconName: 'button',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
  fields: [
    PropField(
      key: 'fontSize',
      kind: FieldKind.doubleNum,
      label: 'Tamanho da fonte',
      group: FieldGroups.style,
    ),
  ],
);

const _hoverDescriptor = WidgetDescriptor(
  type: 'card',
  label: 'Card',
  iconName: 'card',
  category: WidgetCategories.basics,
  slot: SlotKind.none,
  fields: [
    PropField(
      key: 'data',
      kind: FieldKind.string,
      label: 'Texto',
      group: FieldGroups.content,
    ),
    PropField(
      key: 'hoverEnabled',
      kind: FieldKind.boolean,
      label: 'Efeito hover',
      group: FieldGroups.style,
      defaultValue: false,
    ),
    PropField(
      key: 'hoverColor',
      kind: FieldKind.string,
      label: 'Cor do hover',
      group: FieldGroups.style,
      visibleWhen: PropEquals('hoverEnabled', true),
    ),
    PropField(
      key: 'hoverPadding',
      kind: FieldKind.string,
      label: 'Margem do hover',
      group: FieldGroups.spacing,
      visibleWhen: PropEquals('hoverEnabled', true),
    ),
  ],
);

Future<void> _pumpList(
  WidgetTester tester, {
  Map<String, dynamic> properties = const {},
  WidgetDescriptor descriptor = _descriptor,
  ValueNotifier<Set<String>>? collapsedSections,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 700,
          child: InspectorPropList(
            onBindProp: (_, _) {},
            onUnbindProp: (_) {},
            ownerKey: 'n1',
            properties: properties,
            descriptor: descriptor,
            onUpdateProps: (_) {},
            collapsedSections: collapsedSections,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('seções por grupo', () {
    testWidgets('cada grupo do descriptor vira uma seção', (tester) async {
      await _pumpList(tester);

      expect(find.byType(PropSection), findsNWidgets(2));
      expect(find.text('CONTEÚDO'), findsOneWidget);
      expect(find.text('ESTILO'), findsOneWidget);
    });

    testWidgets('seção nasce aberta, mostrando os campos', (tester) async {
      await _pumpList(tester);

      expect(find.byType(PropFieldEditor), findsNWidgets(3));
    });

    testWidgets('fechar a seção esconde os campos dela', (tester) async {
      await _pumpList(tester);

      await tester.tap(find.text('ESTILO'));
      await tester.pumpAndSettle();

      expect(find.byType(PropFieldEditor), findsNWidgets(2));
      expect(find.text('Tamanho da fonte'), findsNothing);
    });

    testWidgets('resumo só aparece com a seção fechada', (tester) async {
      await _pumpList(tester, properties: {'fontSize': 18.0});

      final resumo = find.descendant(
        of: find.byType(PropSectionHeader),
        matching: find.text('18'),
      );
      expect(resumo, findsNothing);

      await tester.tap(find.text('ESTILO'));
      await tester.pumpAndSettle();

      expect(resumo, findsOneWidget);
    });
  });

  group('busca de propriedade', () {
    testWidgets('filtra por label, escondendo a seção que esvazia', (
      tester,
    ) async {
      await _pumpList(tester);

      await tester.enterText(find.byType(SearchField), 'fonte');
      await tester.pumpAndSettle();

      expect(find.byType(PropSection), findsOneWidget);
      expect(find.text('ESTILO'), findsOneWidget);
      expect(find.text('CONTEÚDO'), findsNothing);
    });

    testWidgets('filtra também pela chave da prop', (tester) async {
      await _pumpList(tester);

      await tester.enterText(find.byType(SearchField), 'maxLines');
      await tester.pumpAndSettle();

      expect(find.byType(PropFieldEditor), findsOneWidget);
      expect(find.text('Máximo de linhas'), findsOneWidget);
    });

    testWidgets('busca sem resultado mostra o estado vazio', (tester) async {
      await _pumpList(tester);

      await tester.enterText(find.byType(SearchField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.byType(PropSection), findsNothing);
      expect(find.text('Nenhuma propriedade encontrada.'), findsOneWidget);
    });

    testWidgets('limpar a busca traz tudo de volta', (tester) async {
      await _pumpList(tester);

      await tester.enterText(find.byType(SearchField), 'fonte');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchField), '');
      await tester.pumpAndSettle();

      expect(find.byType(PropSection), findsNWidgets(2));
    });
  });

  group('colapso persistido por grupo (F6, Q2/P3)', () {
    testWidgets(
      'um grupo presente em collapsedSections nasce fechado',
      (tester) async {
        await _pumpList(
          tester,
          collapsedSections: ValueNotifier({'Estilo'}),
        );

        expect(find.text('Tamanho da fonte'), findsNothing);
        expect(find.text('Texto'), findsOneWidget);
      },
    );

    testWidgets(
      'fechar uma seção grava o rótulo do grupo em collapsedSections',
      (tester) async {
        final collapsedSections = ValueNotifier<Set<String>>({});
        await _pumpList(tester, collapsedSections: collapsedSections);

        await tester.tap(find.text('ESTILO'));
        await tester.pumpAndSettle();

        expect(collapsedSections.value, {'Estilo'});
      },
    );

    testWidgets(
      'reabrir uma seção remove o rótulo do grupo de collapsedSections',
      (tester) async {
        final collapsedSections = ValueNotifier<Set<String>>({'Estilo'});
        await _pumpList(tester, collapsedSections: collapsedSections);

        await tester.tap(find.text('ESTILO'));
        await tester.pumpAndSettle();

        expect(collapsedSections.value, isEmpty);
      },
    );

    testWidgets(
      'a chave é o rótulo do grupo, não o tipo de nó: dois descriptors '
      'diferentes com o mesmo grupo compartilham o colapso',
      (tester) async {
        final collapsedSections = ValueNotifier<Set<String>>({});
        await _pumpList(tester, collapsedSections: collapsedSections);
        await tester.tap(find.text('ESTILO'));
        await tester.pumpAndSettle();
        expect(collapsedSections.value, {'Estilo'});

        // Desmonta a árvore inteira antes do segundo pump: sem isto, o
        // `PropSection` da nova lista reaproveitaria o `State` do antigo via
        // `ValueKey(group)` (ambos têm uma seção "Estilo"), e o teste
        // passaria mesmo que `initiallyExpanded` não consultasse
        // `collapsedSections` — provando preservação de widget, não
        // compartilhamento de estado.
        await tester.pumpWidget(const SizedBox.shrink());

        await _pumpList(
          tester,
          descriptor: _otherDescriptor,
          collapsedSections: collapsedSections,
        );

        expect(find.text('Tamanho da fonte'), findsNothing);
      },
    );
  });

  group('visibleWhen', () {
    final switchFinder = find.byType(Switch);
    final hoverColor = find.text('Cor do hover');

    Future<List<Map<String, dynamic>>> pumpHover(
      WidgetTester tester, {
      Map<String, dynamic> initial = const {},
    }) async {
      final patches = <Map<String, dynamic>>[];
      var properties = initial;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: StatefulBuilder(
                builder: (context, setState) => InspectorPropList(
                  onBindProp: (_, _) {},
                  onUnbindProp: (_) {},
                  ownerKey: 'n1',
                  properties: properties,
                  descriptor: _hoverDescriptor,
                  onUpdateProps: (patch) {
                    patches.add(patch);
                    setState(() {
                      properties = {...properties, ...patch}
                        ..removeWhere((_, value) => value == null);
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      );
      return patches;
    }

    testWidgets('com o switch desligado, o campo condicional fica fora', (
      tester,
    ) async {
      await pumpHover(tester);

      expect(find.text('Efeito hover'), findsOneWidget);
      expect(hoverColor, findsNothing);
    });

    testWidgets('ligar o switch faz o campo aparecer', (tester) async {
      await pumpHover(tester);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(hoverColor, findsOneWidget);
    });

    testWidgets(
      'esconder e religar devolve o valor, e nenhum patch o remove',
      (tester) async {
        final patches = await pumpHover(
          tester,
          initial: {'hoverEnabled': true},
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('n1_hoverColor')),
            matching: find.byType(TextField),
          ),
          'red',
        );
        await tester.pumpAndSettle();
        final before = patches.length;

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
        expect(hoverColor, findsNothing);

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(hoverColor, findsOneWidget);
        expect(find.text('red'), findsOneWidget);
        final afterEntry = patches.skip(before);
        expect(afterEntry, isNotEmpty);
        expect(
          afterEntry.any((patch) => patch.containsKey('hoverColor')),
          isFalse,
        );
      },
    );

    testWidgets('a seção cujo único campo está escondido não é renderizada', (
      tester,
    ) async {
      await pumpHover(tester);

      expect(find.byType(PropSection), findsNWidgets(2));
      expect(find.text('ESPAÇAMENTO'), findsNothing);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('ESPAÇAMENTO'), findsOneWidget);
    });

    testWidgets('o resumo da seção mista ignora o campo escondido', (
      tester,
    ) async {
      await pumpHover(
        tester,
        initial: {'hoverEnabled': false, 'hoverColor': 'red'},
      );

      await tester.tap(find.text('ESTILO'));
      await tester.pumpAndSettle();

      final summary = find.descendant(
        of: find.byType(PropSectionHeader),
        matching: find.text('Não'),
      );
      expect(summary, findsOneWidget);
      expect(find.text('2 definidas'), findsNothing);
    });

    testWidgets('buscar o rótulo do campo escondido não traz nada', (
      tester,
    ) async {
      await pumpHover(tester);

      await tester.enterText(find.byType(SearchField), 'Cor do hover');
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma propriedade encontrada.'), findsOneWidget);
    });

    testWidgets(
      'alternar o switch não tira o texto nem o foco de outra seção',
      (
        tester,
      ) async {
        await pumpHover(tester);
        final data = find.descendant(
          of: find.byKey(const ValueKey('n1_data')),
          matching: find.byType(TextField),
        );

        await tester.tap(data);
        await tester.enterText(data, 'olá');
        await tester.pumpAndSettle();
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(find.text('olá'), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: data, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
      },
    );

    testWidgets('controle "Misto" na edição em lote deixa o campo à vista', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: InspectorPropList(
                onBindProp: (_, _) {},
                onUnbindProp: (_) {},
                ownerKey: 'multi-n1|n2',
                properties: const {},
                mixedKeys: const {'hoverEnabled'},
                descriptor: _hoverDescriptor,
                onUpdateProps: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(hoverColor, findsOneWidget);
    });
  });
}
