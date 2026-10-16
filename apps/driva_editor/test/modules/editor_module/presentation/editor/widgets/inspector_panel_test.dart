import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Finder _tab(String label) => find.widgetWithText(Tab, label);

Future<void> _pump(
  WidgetTester tester, {
  SduiNode? node,
  bool isRoot = false,
  Map<String, dynamic> safeArea = const {},
  ValueChanged<Map<String, dynamic>>? onUpdateSafeAreaProps,
  List<SduiNode> multiNodes = const [],
  void Function(
    String nodeId,
    Map<String, List<Map<String, dynamic>>?> patch, {
    String? coalesceKey,
  })?
  onUpdateEvents,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 340,
          height: 700,
          child: InspectorPanel(
            onBindProp: (_, _, _) {},
            onUnbindProp: (_, _) {},
            onUpdateEvents: onUpdateEvents ?? (_, _, {coalesceKey}) {},
            multiNodes: multiNodes,
            onUpdatePropsBatch: (_, _) {},
            node: node,
            isRoot: isRoot,
            safeArea: safeArea,
            contentName: 'Home',
            contentSlug: 'home',
            onUpdateProps: (_, _) {},
            onUpdateSafeAreaProps: onUpdateSafeAreaProps ?? (_) {},
            onRemove: (_) {},
            onWrap: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('sem nó selecionado, o Inspector é da página', () {
    testWidgets('cabeçalho identifica a página, não a raiz do conteúdo', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Página'), findsOneWidget);
      expect(find.text('Home · slug home'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('mostra as props da área segura', (tester) async {
      await _pump(tester);

      expect(find.text('Usar área segura'), findsOneWidget);
      expect(find.text('Respeitar o topo'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Espaçamento mínimo'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Espaçamento mínimo'), findsOneWidget);
    });

    testWidgets('editar uma prop chama o callback da página', (tester) async {
      Map<String, dynamic>? patch;
      await _pump(tester, onUpdateSafeAreaProps: (value) => patch = value);

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(patch, {'enabled': false});
    });
  });

  group('com nó selecionado, o Inspector é do nó', () {
    testWidgets('cabeçalho traz o rótulo do widget e a ação de remover', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'text'),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('id nd_1'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Usar área segura'), findsNothing);
    });

    testWidgets('folha sem props editáveis avisa em vez de listar vazio', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'spacer'),
      );

      final descriptor = descriptorFor('spacer')!;
      expect(
        descriptor.fields.isEmpty
            ? find.text('Sem propriedades editáveis.')
            : find.byType(InspectorPropList),
        findsOneWidget,
      );
    });
  });

  group('abas Propriedades | Ações', () {
    testWidgets('um nó mostra as duas abas, com Propriedades ativa', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'text'),
      );

      expect(_tab('Propriedades'), findsOneWidget);
      expect(_tab('Ações'), findsOneWidget);
      expect(find.byType(InspectorPropList), findsOneWidget);
      expect(find.byType(ActionsTab), findsNothing);
    });

    testWidgets('página e seleção múltipla não têm abas', (tester) async {
      await _pump(tester);

      expect(_tab('Propriedades'), findsNothing);
      expect(_tab('Ações'), findsNothing);

      await _pump(
        tester,
        node: const SduiNode(id: 't1', type: 'text'),
        multiNodes: const [
          SduiNode(id: 't1', type: 'text'),
          SduiNode(id: 't2', type: 'text'),
        ],
      );

      expect(find.text('2 nós selecionados'), findsOneWidget);
      expect(_tab('Propriedades'), findsNothing);
      expect(_tab('Ações'), findsNothing);
    });

    testWidgets('a aba Ações continua ativa na troca de nó', (tester) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'text'),
      );
      await tester.tap(_tab('Ações'));
      await tester.pumpAndSettle();

      await _pump(
        tester,
        node: const SduiNode(
          id: 'nd_2',
          type: 'container',
          events: {
            'onTap': [
              {'action': 'navigateBack', 'params': <String, dynamic>{}},
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActionsTab), findsOneWidget);
      expect(find.byType(InspectorPropList), findsNothing);
      expect(find.byType(ConfiguredTriggerCard), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
    });

    testWidgets('adicionar um gatilho grava com o id do nó', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? nodeId;
      Map<String, List<Map<String, dynamic>>?>? patch;
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_box', type: 'container'),
        onUpdateEvents: (id, value, {coalesceKey}) {
          nodeId = id;
          patch = value;
        },
      );

      await tester.tap(_tab('Ações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar gatilho'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ao tocar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mostrar aviso'));
      await tester.pumpAndSettle();

      expect(nodeId, 'nd_box');
      expect(patch, {
        'onTap': [
          {
            'action': 'showSnackBar',
            'params': {'message': '', 'durationMs': 4000},
          },
        ],
      });
    });
  });
}
