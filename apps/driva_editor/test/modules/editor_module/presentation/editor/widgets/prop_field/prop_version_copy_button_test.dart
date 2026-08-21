import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_prop_list.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_field_compare_binding.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockEditorCubit extends Mock implements EditorCubit {}

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

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
  ],
);

const _twoFieldDescriptor = WidgetDescriptor(
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
      min: 1,
      max: 20,
    ),
  ],
);

Finder _copyButtonOfField(String key) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is PropFieldCompareBinding && widget.field.key == key,
  ),
  matching: find.byType(PropVersionCopyButton),
);

ContentSpec _specWithRoot(SduiNode? root) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: root,
);

VersionCompareModeActive _activeState({
  required ContentSpec baseSpec,
  required ContentSpec candidateSpec,
}) => VersionCompareModeActive(
  candidate: LoadedContentVersion(
    version: 3,
    spec: candidateSpec,
    createdAt: DateTime.utc(2026, 8, 16),
  ),
  baseSpec: baseSpec,
  result: compareContentSpecs(baseSpec, candidateSpec),
  versions: const [],
);

void main() {
  group('PropVersionCopyButton em PropFieldEditor', () {
    testWidgets('campo de dimensão em % mostra o botão de cópia', (
      tester,
    ) async {
      const field = PropField(
        key: 'width',
        kind: FieldKind.dimension,
        label: 'Largura',
        group: FieldGroups.size,
        min: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: PropFieldEditor(
                field: field,
                value: '70%',
                onChanged: (_) {},
                onCopyFromVersion: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PropVersionCopyButton), findsOneWidget);
    });
  });

  group('PropFieldCompareBinding via InspectorPropList', () {
    late _MockEditorCubit editorCubit;

    setUp(() {
      editorCubit = _MockEditorCubit();
      when(() => editorCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => editorCubit.state).thenReturn(
        EditorReady(
          document: _specWithRoot(
            const SduiNode(
              id: 'n_text',
              type: 'text',
              properties: {'data': 'Do rascunho'},
            ),
          ),
        ),
      );
    });

    VersionCompareModeCubit buildCompareCubit() => VersionCompareModeCubit(
      getContentVersionUseCase: _MockGetContentVersionUseCase(),
      getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
      editorCubit: editorCubit,
    );

    Widget harness({
      required VersionCompareModeCubit compareCubit,
      required Map<String, dynamic> properties,
      WidgetDescriptor descriptor = _descriptor,
    }) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 700,
            child: VersionCompareModeScope(
              cubit: compareCubit,
              child: InspectorPropList(
                ownerKey: 'n_text',
                nodeId: 'n_text',
                properties: properties,
                descriptor: descriptor,
                onUpdateProps: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('nó cujo tipo mudou não oferece o botão', (tester) async {
      final compareCubit = buildCompareCubit();
      addTearDown(compareCubit.close);

      compareCubit.emit(
        _activeState(
          baseSpec: _specWithRoot(
            const SduiNode(
              id: 'n_text',
              type: 'text',
              properties: {'data': 'Do rascunho'},
            ),
          ),
          candidateSpec: _specWithRoot(
            const SduiNode(
              id: 'n_text',
              type: 'button',
              properties: {'data': 'Do candidato'},
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        harness(
          compareCubit: compareCubit,
          properties: const {'data': 'Do rascunho'},
        ),
      );
      await tester.pump();

      expect(find.byType(PropVersionCopyButton), findsNothing);
    });

    testWidgets(
      'propriedade fora de changedPropertyKeys não oferece o botão',
      (tester) async {
        final compareCubit = buildCompareCubit();
        addTearDown(compareCubit.close);

        compareCubit.emit(
          _activeState(
            baseSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Igual nas duas versões'},
              ),
            ),
            candidateSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Igual nas duas versões'},
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          harness(
            compareCubit: compareCubit,
            properties: const {'data': 'Igual nas duas versões'},
          ),
        );
        await tester.pump();

        expect(find.byType(PropVersionCopyButton), findsNothing);
      },
    );

    testWidgets(
      'num nó de duas propriedades, só o campo da chave alterada ganha a seta',
      (tester) async {
        final compareCubit = buildCompareCubit();
        addTearDown(compareCubit.close);

        compareCubit.emit(
          _activeState(
            baseSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Do rascunho', 'maxLines': 2},
              ),
            ),
            candidateSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Do candidato', 'maxLines': 2},
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          harness(
            compareCubit: compareCubit,
            properties: const {'data': 'Do rascunho', 'maxLines': 2},
            descriptor: _twoFieldDescriptor,
          ),
        );
        await tester.pump();

        expect(_copyButtonOfField('data'), findsOneWidget);
        expect(_copyButtonOfField('maxLines'), findsNothing);
        expect(find.byType(PropVersionCopyButton), findsOneWidget);
      },
    );

    testWidgets(
      'tocar o botão chama EditorCubit.copyPropertyFromVersion com a chave '
      'do campo e o valor da candidata',
      (tester) async {
        final compareCubit = buildCompareCubit();
        addTearDown(compareCubit.close);

        compareCubit.emit(
          _activeState(
            baseSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Do rascunho'},
              ),
            ),
            candidateSpec: _specWithRoot(
              const SduiNode(
                id: 'n_text',
                type: 'text',
                properties: {'data': 'Do candidato'},
              ),
            ),
          ),
        );

        await tester.pumpWidget(
          harness(
            compareCubit: compareCubit,
            properties: const {'data': 'Do rascunho'},
          ),
        );
        await tester.pump();

        expect(find.byType(PropVersionCopyButton), findsOneWidget);

        await tester.tap(find.byType(PropVersionCopyButton));
        await tester.pump();

        verify(
          () => editorCubit.copyPropertyFromVersion(
            'n_text',
            'data',
            'Do candidato',
          ),
        ).called(1);
      },
    );
  });
}
