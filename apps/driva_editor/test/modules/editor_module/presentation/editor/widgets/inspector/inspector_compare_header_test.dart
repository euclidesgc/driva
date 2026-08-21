import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _fullVersionLoadLabel = 'Carregar versão inteira no rascunho';

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
    'nó com propriedades alteradas e mesmo tipo mostra a contagem, sem '
    'nenhum controle de cópia',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(diff: _diff(), candidateVersion: 3),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Propriedades alteradas'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(
        find.textContaining('propriedade alterada'),
        findsNothing,
        reason: 'sem changedPropertyKeys, não há contagem para mostrar',
      );
    },
  );

  testWidgets('tipo mudou: chip explica, sem contagem de propriedades', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        InspectorCompareHeader(
          diff: _diff(candidateType: 'container'),
          candidateVersion: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tipo mudou'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('nó só no rascunho: chip explica, sem nenhum controle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const InspectorCompareHeader(isOnlyInDraft: true, candidateVersion: 3),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Somente no rascunho'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('modo página: safe area alterada aparece como chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const InspectorCompareHeader(
          safeAreaChanged: true,
          candidateVersion: 3,
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
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('nó sem diferença nenhuma não desenha cabeçalho', (tester) async {
    await tester.pumpWidget(
      _harness(
        InspectorCompareHeader(
          diff: _diff(propertiesChanged: false),
          candidateVersion: 3,
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
            diff: _diff(candidateType: 'container'),
            candidateVersion: 3,
            changedPropertyKeys: const {'data', 'shape'},
            descriptor: _textDescriptor,
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
    'chave alterada sem PropField no descriptor aparece nomeada, apontando '
    'a seta que carrega a versão inteira',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            diff: _diff(),
            candidateVersion: 3,
            changedPropertyKeys: const {'data', 'shape'},
            descriptor: _textDescriptor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('shape'), findsOneWidget);
      expect(find.textContaining('data'), findsNothing);
      expect(find.textContaining(_fullVersionLoadLabel), findsOneWidget);
    },
  );

  testWidgets(
    'a contagem exibida vem de changedPropertyKeys, o único dado de '
    'comparação que o cabeçalho recebe',
    (tester) async {
      final changedKeys = {'data', 'shape', 'color'};
      await tester.pumpWidget(
        _harness(
          InspectorCompareHeader(
            diff: _diff(),
            candidateVersion: 3,
            changedPropertyKeys: changedKeys,
            descriptor: _textDescriptor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('${changedKeys.length} propriedades alteradas'),
        findsOneWidget,
      );
    },
  );
}
