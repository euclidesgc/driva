import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_surface.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/selectable_node.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_draft_legend.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/editing_lock.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette/widget_palette.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_palette_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockPublishContentUseCase extends Mock
    implements PublishContentUseCase {}

class _MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class _MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

void main() {
  const root = SduiNode(
    id: 'root',
    type: 'column',
    children: [SduiNode(id: 'text', type: 'text')],
  );

  Widget hosted(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(width: 340, height: 700, child: child),
    ),
  );

  Widget palette({required bool isReadOnly}) => hosted(
    WidgetPalettePanel(
      collapsedCategories: ValueNotifier({}),
      isReadOnly: isReadOnly,
    ),
  );

  Widget tree({required bool isReadOnly, ValueChanged<String?>? onSelect}) =>
      hosted(
        WidgetTreePanel(
          root: root,
          selectedNodeId: null,
          nodeDiagnostics: const {},
          isReadOnly: isReadOnly,
          onSelect: onSelect ?? (_) {},
          onRemove: (_) {},
          onDropNew: (_, _) {},
          onDropMove: (_, _) {},
          onDropNewAt: (_, _, _) {},
          onDropMoveAt: (_, _, _) {},
        ),
      );

  Widget inspector({required bool isReadOnly}) => hosted(
    InspectorPanel(
      node: const SduiNode(id: 'text', type: 'text'),
      isRoot: false,
      safeArea: const {},
      contentName: 'Home',
      contentSlug: 'home',
      isReadOnly: isReadOnly,
      onUpdateProps: (_, _) {},
      onUpdateSafeAreaProps: (_) {},
      onRemove: (_) {},
      onWrap: (_) {},
    ),
  );

  group('paleta congelada', () {
    testWidgets('nenhum item é arrastável, e o item continua na tela', (
      tester,
    ) async {
      await tester.pumpWidget(palette(isReadOnly: true));

      expect(find.byType(PaletteItem), findsWidgets);
      expect(find.byType(Draggable<Object>), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == 'Feche a comparação para editar',
        ),
        findsWidgets,
      );
    });

    testWidgets('liberada, os itens voltam a ser arrastáveis', (tester) async {
      await tester.pumpWidget(palette(isReadOnly: false));

      expect(
        tester
            .widgetList<PaletteItem>(find.byType(PaletteItem))
            .every((item) => item.isDraggable),
        isTrue,
      );
    });
  });

  group('árvore congelada', () {
    testWidgets('sem faixas de soltura e sem botão de excluir na linha', (
      tester,
    ) async {
      await tester.pumpWidget(tree(isReadOnly: true));

      expect(find.byType(DropZone), findsNothing);
      expect(find.byType(TreeGapDropZone), findsNothing);
      expect(
        tester
            .widgetList<TreeRow>(find.byType(TreeRow))
            .every((row) => row.onRemove == null && !row.isDraggable),
        isTrue,
      );
    });

    testWidgets('selecionar continua funcionando — ler não é editar', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        tree(isReadOnly: true, onSelect: (id) => selected = id),
      );

      await tester.tap(find.byType(TreeRow).last);

      expect(selected, 'text');
    });

    testWidgets('liberada, as faixas de soltura voltam', (tester) async {
      await tester.pumpWidget(tree(isReadOnly: false));

      expect(find.byType(DropZone), findsOneWidget);
    });
  });

  group('Inspector congelado', () {
    testWidgets('campos inertes, cabeçalho sem excluir nem envolver', (
      tester,
    ) async {
      await tester.pumpWidget(inspector(isReadOnly: true));

      final locks = tester.widgetList<EditingLock>(find.byType(EditingLock));
      expect(locks, isNotEmpty);
      expect(locks.every((lock) => lock.locked), isTrue);

      final header = tester.widget<InspectorHeader>(
        find.byType(InspectorHeader),
      );
      expect(header.onRemove, isNull);
      expect(header.onWrap, isNull);
    });

    testWidgets('liberado, os campos respondem de novo', (tester) async {
      await tester.pumpWidget(inspector(isReadOnly: false));

      expect(
        tester
            .widgetList<EditingLock>(find.byType(EditingLock))
            .every((lock) => !lock.locked),
        isTrue,
      );
      final header = tester.widget<InspectorHeader>(
        find.byType(InspectorHeader),
      );
      expect(header.onRemove, isNotNull);
    });
  });

  group('mock do rascunho congelado', () {
    late EditorCubit cubit;

    const document = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: root,
    );

    setUp(() {
      cubit = EditorCubit(
        loadContentUseCase: _MockLoadContentUseCase(),
        saveDraftUseCase: _MockSaveDraftUseCase(),
        publishContentUseCase: _MockPublishContentUseCase(),
        unpublishContentUseCase: _MockUnpublishContentUseCase(),
        restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
        projectId: 'p1',
      )..emit(const EditorReady(document: document));
    });

    tearDown(() => cubit.close());

    Future<void> pumpSurface(WidgetTester tester) => tester.pumpWidget(
      hosted(
        BlocProvider<EditorCubit>.value(
          value: cubit,
          child: PreviewSurface(onSelect: (_) {}, onDropOn: (_, _) {}),
        ),
      ),
    );

    bool everyNodeDraggable(WidgetTester tester) => tester
        .widgetList<SelectableNode>(find.byType(SelectableNode))
        .every((node) => node.isDraggable);

    testWidgets('congelar tira o arraste dos nós, e descongelar devolve', (
      tester,
    ) async {
      await pumpSurface(tester);
      expect(find.byType(SelectableNode), findsWidgets);
      expect(everyNodeDraggable(tester), isTrue);

      cubit.setReadOnly(value: true);
      await tester.pumpAndSettle();

      expect(everyNodeDraggable(tester), isFalse);

      cubit.setReadOnly(value: false);
      await tester.pumpAndSettle();

      expect(everyNodeDraggable(tester), isTrue);
    });
  });

  testWidgets('a legenda do rascunho anuncia o congelamento', (tester) async {
    await tester.pumpWidget(hosted(const CanvasCompareDraftLegend()));

    expect(find.text('Rascunho (somente leitura)'), findsOneWidget);
    expect(
      find.byIcon(Icons.lock_outline),
      findsOneWidget,
      reason: 'cor não pode ser o único sinal do estado',
    );
  });
}
