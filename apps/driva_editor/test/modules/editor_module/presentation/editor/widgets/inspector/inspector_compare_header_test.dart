import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_version_copy_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _copyLabel = 'Trazer todas as propriedades desta versão';

const _textDescriptor = WidgetDescriptor(
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
  ],
);

NodeDiff _diff({
  String baseType = 'text',
  String candidateType = 'text',
  bool propertiesChanged = true,
  bool eventsChanged = false,
}) => NodeDiff(
  nodeId: 'nd_1',
  baseType: baseType,
  candidateType: candidateType,
  propertiesChanged: propertiesChanged,
  eventsChanged: eventsChanged,
  childOrderChanged: false,
  baseParentId: null,
  candidateParentId: null,
);

Widget _harness(InspectorCompareHeader header) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: header)),
);

void main() {
  testWidgets(
    'nó com propriedades alteradas e mesmo tipo oferece trazer as '
    'propriedades, e acionar informa o nó',
    (tester) async {
      final copied = <String>[];
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            nodeId: 'nd_1',
            diff: _diff(),
            candidateVersion: 3,
            onCopyNodeProperties: copied.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, _copyLabel), findsOneWidget);
      expect(find.text('Propriedades alteradas'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, _copyLabel));
      await tester.pump();
      expect(copied, ['nd_1']);
    },
  );

  testWidgets(
    'tipo mudou: sem botão, e o cabeçalho explica por que e aponta a '
    'alternativa segura',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            nodeId: 'nd_1',
            diff: _diff(candidateType: 'container'),
            candidateVersion: 3,
            onCopyNodeProperties: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, _copyLabel),
        findsNothing,
        reason:
            'botão inexistente, nunca desabilitado — desabilitado deixaria o '
            'usuário procurando o que o destravaria',
      );
      expect(find.text('Tipo mudou'), findsOneWidget);
      expect(
        find.textContaining('Carregar versão inteira no rascunho'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'nó só no rascunho: sem botão, com a explicação de que não há o que '
    'trazer',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            nodeId: 'nd_1',
            isOnlyInDraft: true,
            candidateVersion: 3,
            onCopyNodeProperties: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, _copyLabel), findsNothing);
      expect(find.text('Somente no rascunho'), findsOneWidget);
    },
  );

  testWidgets(
    'modo página: safe area alterada aparece como chip, sem botão de nó',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            safeAreaChanged: true,
            candidateVersion: 3,
            onCopyNodeProperties: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(VersionCompareMarkerChip, 'Safe area alterada'),
        findsOneWidget,
        reason:
            'o critério é chip, não texto solto — cor nunca é o único '
            'sinal, então o rótulo precisa vir dentro do chip que traz o ícone',
      );
      expect(find.widgetWithText(OutlinedButton, _copyLabel), findsNothing);
    },
  );

  testWidgets('nó sem diferença nenhuma não desenha cabeçalho', (tester) async {
    await tester.pumpWidget(
      _harness(
        InspectorCompareHeader(
          nodeId: 'nd_1',
          diff: _diff(propertiesChanged: false),
          candidateVersion: 3,
          onCopyNodeProperties: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Comparando com a versão'), findsNothing);
  });

  testWidgets(
    'tipo mudou: mesmo com changedPropertyKeys/descriptor preenchidos, não '
    'renderiza a contagem nem a linha "Sem campo no Inspector" — '
    'comparar propriedades de tipos diferentes não tem significado',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            nodeId: 'nd_1',
            diff: _diff(candidateType: 'container'),
            candidateVersion: 3,
            changedPropertyKeys: const {'data', 'shape'},
            descriptor: _textDescriptor,
            onCopyNodeProperties: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('propriedades alteradas'), findsNothing);
      expect(find.textContaining('propriedade alterada'), findsNothing);
      expect(find.textContaining('Sem campo no Inspector'), findsNothing);
      expect(find.textContaining('shape'), findsNothing);
    },
  );

  testWidgets(
    'chave alterada sem PropField no descriptor aparece nomeada, avisando '
    'que só a ação de nó inteiro alcança',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            nodeId: 'nd_1',
            diff: _diff(),
            candidateVersion: 3,
            changedPropertyKeys: const {'data', 'shape'},
            descriptor: _textDescriptor,
            onCopyNodeProperties: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('shape'), findsOneWidget);
      expect(find.textContaining('data'), findsNothing);
      expect(find.textContaining(_copyLabel), findsWidgets);
    },
  );

  testWidgets(
    'a contagem exibida vem de changedPropertyKeys, não da lista de botões '
    'de cópia por campo montada ao lado',
    (tester) async {
      final changedKeys = {'data', 'shape', 'color'};
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  InspectorCompareHeader(
                    nodeId: 'nd_1',
                    diff: _diff(),
                    candidateVersion: 3,
                    changedPropertyKeys: changedKeys,
                    descriptor: _textDescriptor,
                    onCopyNodeProperties: (_) {},
                  ),
                  PropVersionCopyButton(onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PropVersionCopyButton), findsNWidgets(1));
      expect(
        find.textContaining('${changedKeys.length} propriedades alteradas'),
        findsOneWidget,
      );
    },
  );
}
