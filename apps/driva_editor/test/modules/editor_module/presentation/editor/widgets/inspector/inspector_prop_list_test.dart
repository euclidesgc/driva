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
}
