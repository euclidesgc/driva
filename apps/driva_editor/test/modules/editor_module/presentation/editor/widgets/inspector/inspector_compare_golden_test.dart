import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/inspector_compare_section.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

class _MockEditorCubit extends Mock implements EditorCubit {}

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

const _selectedNode = SduiNode(
  id: 'nd_title',
  type: 'text',
  properties: {'data': 'Promoção de inverno', 'fontSize': 14.0},
);

const _draft = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      _selectedNode,
      SduiNode(
        id: 'nd_cta',
        type: 'button',
        properties: {'label': 'Ver ofertas'},
      ),
    ],
  ),
);

const _candidate = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      SduiNode(
        id: 'nd_title',
        type: 'text',
        properties: {
          'data': 'Promoção de verão',
          'fontSize': 22.0,
          'letterSpacing': 1.5,
        },
      ),
      SduiNode(
        id: 'nd_cta',
        type: 'button',
        properties: {'label': 'Ver ofertas'},
      ),
    ],
  ),
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  late _MockEditorCubit editorCubit;
  late VersionCompareModeCubit compareCubit;

  setUp(() {
    editorCubit = _MockEditorCubit();
    when(() => editorCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => editorCubit.state,
    ).thenReturn(const EditorReady(document: _draft));
    compareCubit =
        VersionCompareModeCubit(
          getContentVersionUseCase: _MockGetContentVersionUseCase(),
          getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
          editorCubit: editorCubit,
        )..emit(
          VersionCompareModeActive(
            candidate: LoadedContentVersion(
              version: 7,
              spec: _candidate,
              createdAt: DateTime.utc(2026, 8, 16),
            ),
            baseSpec: _draft,
            result: compareContentSpecs(_draft, _candidate),
          ),
        );
  });

  tearDown(() => compareCubit.close());

  testWidgets(
    'golden: painel direito em modo comparação — cabeçalho informativo, sem '
    'controle de cópia por propriedade',
    (tester) async {
      tester.view.physicalSize = const Size(340, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: VersionCompareModeScope(
              cubit: compareCubit,
              child: InspectorPanel(
                node: _selectedNode,
                isRoot: false,
                safeArea: const {},
                contentName: 'Home',
                contentSlug: 'home',
                compareSection: const InspectorCompareSection(
                  nodeId: 'nd_title',
                ),
                onUpdateProps: (_, _) {},
                onUpdateSafeAreaProps: (_) {},
                onRemove: (_) {},
                onWrap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(OutlinedButton),
        findsNothing,
        reason:
            'a única ação de restauração é a seta da barra da candidata, '
            'fora do Inspector — nenhum controle de cópia por propriedade '
            'ou por nó é montado aqui',
      );

      expect(
        find.descendant(
          of: find.byType(InspectorPropList),
          matching: find.byWidgetPredicate(_mentionsCopyFromVersion),
        ),
        findsNothing,
        reason:
            'nenhum controle acionável na lista de propriedades pode ter '
            'tooltip ou rótulo semântico que fale em trazer/copiar o valor '
            'da versão — a restauração é só a seta da barra da candidata, '
            'fora do Inspector',
      );

      await expectLater(
        find.byType(InspectorPanel),
        matchesGoldenFile('goldens/inspector_panel_compare_mode.png'),
      );
    },
  );
}

bool _mentionsCopyFromVersion(Widget widget) {
  final text = switch (widget) {
    Tooltip() => widget.message,
    Semantics() => widget.properties.label,
    _ => null,
  };
  if (text == null) return false;
  final lower = text.toLowerCase();
  return lower.contains('vers') &&
      (lower.contains('traz') || lower.contains('copi'));
}
