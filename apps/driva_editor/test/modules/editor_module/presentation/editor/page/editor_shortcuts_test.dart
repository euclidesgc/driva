import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockEditorCubit extends MockCubit<EditorState> implements EditorCubit {}

void main() {
  const content = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(id: 'nd_root', type: 'column'),
  );

  const fieldKey = Key('campo');

  late MockEditorCubit cubit;

  setUp(() {
    cubit = MockEditorCubit();
    whenListen(
      cubit,
      const Stream<EditorState>.empty(),
      initialState: const EditorReady(
        document: content,
        selectedNodeId: 'nd_root',
      ),
    );
  });

  Future<void> pumpEditor(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<EditorCubit>.value(
        value: cubit,
        child: const EditorShortcuts(
          child: Scaffold(body: TextField(key: fieldKey)),
        ),
      ),
    ),
  );

  Future<void> pressWithControl(WidgetTester tester, LogicalKeyboardKey key) =>
      tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft).then((_) async {
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      });

  Future<void> focusTextField(WidgetTester tester) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pump();
  }

  group('sem foco em campo de texto', () {
    testWidgets('Delete apaga o nó selecionado', (tester) async {
      await pumpEditor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      verify(cubit.removeSelected).called(1);
    });

    testWidgets('Ctrl+D duplica', (tester) async {
      await pumpEditor(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyD);

      verify(cubit.duplicateSelected).called(1);
    });

    testWidgets('Ctrl+C e Ctrl+V copiam e colam o nó', (tester) async {
      await pumpEditor(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyC);
      await pressWithControl(tester, LogicalKeyboardKey.keyV);

      verify(cubit.copySelected).called(1);
      verify(cubit.paste).called(1);
    });

    testWidgets('Escape limpa a seleção', (tester) async {
      await pumpEditor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      verify(() => cubit.selectNode(null)).called(1);
    });
  });

  group('com o cursor num campo de texto', () {
    testWidgets('Delete não apaga o nó', (tester) async {
      await pumpEditor(tester);
      await focusTextField(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      verifyNever(cubit.removeSelected);
    });

    testWidgets('Ctrl+D não duplica', (tester) async {
      await pumpEditor(tester);
      await focusTextField(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyD);

      verifyNever(cubit.duplicateSelected);
    });

    testWidgets('Ctrl+C não copia o nó', (tester) async {
      await pumpEditor(tester);
      await focusTextField(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyC);

      verifyNever(cubit.copySelected);
    });

    testWidgets('Escape não limpa a seleção', (tester) async {
      await pumpEditor(tester);
      await focusTextField(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      verifyNever(() => cubit.selectNode(null));
    });
  });

  group('atalhos globais valem mesmo digitando', () {
    testWidgets('Ctrl+Z desfaz', (tester) async {
      await pumpEditor(tester);
      await focusTextField(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyZ);

      verify(cubit.undo).called(1);
    });

    testWidgets('Ctrl+Y refaz', (tester) async {
      await pumpEditor(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyY);

      verify(cubit.redo).called(1);
    });

    testWidgets('Ctrl+Shift+Z refaz', (tester) async {
      await pumpEditor(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      verify(cubit.redo).called(1);
    });

    testWidgets('Ctrl+S salva', (tester) async {
      when(cubit.save).thenAnswer((_) async {});
      await pumpEditor(tester);
      await focusTextField(tester);

      await pressWithControl(tester, LogicalKeyboardKey.keyS);

      verify(cubit.save).called(1);
    });
  });
}
