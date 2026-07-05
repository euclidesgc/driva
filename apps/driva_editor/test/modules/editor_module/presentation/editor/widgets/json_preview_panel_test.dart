import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/json_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

ContentSpec _docWithText(String text) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      SduiNode(id: 'nd_text', type: 'text', properties: {'data': text}),
    ],
  ),
);

void main() {
  late EditorCubit cubit;

  setUp(() {
    cubit = EditorCubit(
      loadContentUseCase: _MockLoadContentUseCase(),
      saveDraftUseCase: _MockSaveDraftUseCase(),
    );
    cubit.emit(EditorReady(document: _docWithText('hello')));
  });

  tearDown(() => cubit.close());

  Widget harness() => MaterialApp(
    home: Scaffold(
      body: BlocProvider.value(value: cubit, child: const JsonPreviewPanel()),
    ),
  );

  SelectableText jsonText(WidgetTester tester) =>
      tester.widget<SelectableText>(find.byType(SelectableText));

  String renderedJson(WidgetTester tester) {
    final span = jsonText(tester).textSpan!;
    final buffer = StringBuffer();
    span.visitChildren((s) {
      buffer.write((s as TextSpan).text ?? '');
      return true;
    });
    return buffer.toString();
  }

  testWidgets('renderiza o JSON do spec inicial', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    final json = renderedJson(tester);
    expect(json, contains('"kind": "content"'));
    expect(json, contains('"slug": "home"'));
    expect(json, contains('"hello"'));
  });

  testWidgets('atualiza ao editar o documento (após a janela do throttle)', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pump();
    expect(renderedJson(tester), contains('"hello"'));

    cubit.updateProps('nd_text', {'data': 'world'});
    await tester.pump();
    await tester.pump();

    expect(renderedJson(tester), contains('"world"'));
    expect(renderedJson(tester), isNot(contains('"hello"')));
  });

  testWidgets('copiar envia o JSON para o clipboard e mostra "Copiado"', (
    tester,
  ) async {
    final captured = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          captured.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('Copiar'), findsOneWidget);
    await tester.tap(find.text('Copiar'));
    await tester.pump();

    expect(captured, isNotEmpty);
    expect(captured.single, contains('"slug": "home"'));
    expect(find.text('Copiado'), findsOneWidget);
  });
}
