import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
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

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

ContentSpec _spec({required String textA, required String textB}) =>
    ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(
        id: 'n_root',
        type: 'column',
        children: [
          SduiNode(id: 'n_a', type: 'text', properties: {'data': textA}),
          SduiNode(id: 'n_b', type: 'text', properties: {'data': textB}),
        ],
      ),
    );

String _textOf(EditorCubit cubit, String nodeId) {
  final document = (cubit.state as EditorReady).document;
  final children = document.root!.children;
  return children.firstWhere((node) => node.id == nodeId).properties['data']
      as String;
}

void main() {
  test(
    'fechar a comparação depois de duas cópias mantém as duas, e dois undos '
    'desfazem uma de cada vez, na ordem inversa (T5b.20)',
    () async {
      final draft = _spec(textA: 'A do rascunho', textB: 'B do rascunho');
      final candidateSpec = _spec(textA: 'A da versão', textB: 'B da versão');
      final editorCubit = EditorCubit(
        loadContentUseCase: _MockLoadContentUseCase(),
        saveDraftUseCase: _MockSaveDraftUseCase(),
        publishContentUseCase: _MockPublishContentUseCase(),
        unpublishContentUseCase: _MockUnpublishContentUseCase(),
        restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
        projectId: 'p1',
      )..emit(EditorReady(document: draft));
      final compareCubit =
          VersionCompareModeCubit(
              getContentVersionUseCase: _MockGetContentVersionUseCase(),
              getContentVersionsUseCase: _MockGetContentVersionsUseCase(),
              editorCubit: editorCubit,
            )
            ..emit(
              VersionCompareModeActive(
                candidate: LoadedContentVersion(
                  version: 2,
                  spec: candidateSpec,
                  createdAt: DateTime.utc(2026, 8, 16),
                ),
                baseSpec: draft,
                result: compareContentSpecs(draft, candidateSpec),
                versions: const [],
              ),
            )
            ..copyNodeProperties('n_a')
            ..copyNodeProperties('n_b')
            ..exit();

      expect(compareCubit.state, const VersionCompareModeInactive());
      expect(_textOf(editorCubit, 'n_a'), 'A da versão');
      expect(_textOf(editorCubit, 'n_b'), 'B da versão');

      editorCubit.undo();
      expect(_textOf(editorCubit, 'n_a'), 'A da versão');
      expect(_textOf(editorCubit, 'n_b'), 'B do rascunho');

      editorCubit.undo();
      expect(_textOf(editorCubit, 'n_a'), 'A do rascunho');
      expect(_textOf(editorCubit, 'n_b'), 'B do rascunho');

      await compareCubit.close();
      await editorCubit.close();
    },
  );
}
