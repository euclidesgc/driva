import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeEditorLayoutRepository implements EditorLayoutRepository {
  EditorLayoutSnapshot? stored;
  bool corrupted = false;
  int saveCount = 0;

  @override
  Future<Either<Failure, EditorLayoutSnapshot>> getLayout() async {
    if (corrupted) return const Left(ValidationFailure('corrompido'));
    return Right(stored ?? const EditorLayoutSnapshot());
  }

  @override
  Future<Either<Failure, Unit>> saveLayout(EditorLayoutSnapshot layout) async {
    stored = layout;
    saveCount++;
    return const Right(unit);
  }
}

void main() {
  group('EditorLayoutController', () {
    test('nasce com o padrão quando nenhum layout inicial é informado', () {
      final controller = EditorLayoutController();

      expect(controller.value, const EditorLayout());
    });

    test('aceita um layout inicial diferente do padrão', () {
      const initial = EditorLayout(leftPanelCollapsed: true);

      final controller = EditorLayoutController(initial: initial);

      expect(controller.value, initial);
    });

    test('collapseLeftPanel colapsa só o painel esquerdo e notifica', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.collapseLeftPanel();

      expect(controller.value.leftPanelCollapsed, isTrue);
      expect(controller.value.rightPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('expandLeftPanel expande o painel esquerdo e notifica', () {
      final controller = EditorLayoutController(
        initial: const EditorLayout(leftPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandLeftPanel();

      expect(controller.value.leftPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('collapseRightPanel colapsa só o painel direito e notifica', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.collapseRightPanel();

      expect(controller.value.rightPanelCollapsed, isTrue);
      expect(controller.value.leftPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('expandRightPanel expande o painel direito e notifica', () {
      final controller = EditorLayoutController(
        initial: const EditorLayout(rightPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandRightPanel();

      expect(controller.value.rightPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('setLeftPanelTab troca a aba sem alterar o colapso', () {
      final controller = EditorLayoutController(
        initial: const EditorLayout(leftPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.setLeftPanelTab(LeftPanelTab.tree);

      expect(controller.value.leftPanelTab, LeftPanelTab.tree);
      expect(controller.value.leftPanelCollapsed, isTrue);
      expect(notifications, 1);
    });

    test(
      'showLeftPanelTab reabre o painel já na aba pedida (D2, aceite 26)',
      () {
        final controller = EditorLayoutController(
          initial: const EditorLayout(leftPanelCollapsed: true),
        );
        var notifications = 0;
        controller.addListener(() => notifications++);
        expect(notifications, 0);

        controller.showLeftPanelTab(LeftPanelTab.tree);

        expect(controller.value.leftPanelCollapsed, isFalse);
        expect(controller.value.leftPanelTab, LeftPanelTab.tree);
        expect(notifications, 1);
      },
    );

    test('não notifica quando o novo valor é igual ao atual', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandLeftPanel();

      expect(notifications, 0);
    });

    test('setLeftPanelWidth/setRightPanelWidth atualizam e notificam', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller
        ..addListener(() => notifications++)
        ..setLeftPanelWidth(300)
        ..setRightPanelWidth(350);

      expect(controller.value.leftPanelWidth, 300);
      expect(controller.value.rightPanelWidth, 350);
      expect(notifications, 2);
    });

    test(
      'sem getLayoutUseCase (D19), ready já resolve — não há boot a esperar',
      () async {
        final controller = EditorLayoutController();

        await controller.ready;

        expect(controller.value, const EditorLayout());
      },
    );
  });

  group('persistência (F6)', () {
    late _FakeEditorLayoutRepository repository;
    late GetEditorLayoutUseCase getLayout;
    late SaveEditorLayoutUseCase saveLayout;

    setUp(() {
      repository = _FakeEditorLayoutRepository();
      getLayout = GetEditorLayoutUseCase(repository: repository);
      saveLayout = SaveEditorLayoutUseCase(repository: repository);
    });

    test(
      'aceite 30 — reclamp (D13): largura fora do teto/piso chega já '
      'clampada depois do boot',
      () async {
        repository.stored = const EditorLayoutSnapshot(
          leftPanelWidth: 900,
          rightPanelWidth: 10,
        );
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        addTearDown(controller.dispose);

        await controller.ready;

        expect(
          controller.value.leftPanelWidth,
          AppSizes.workspacePanelMaxWidth,
        );
        expect(
          controller.value.rightPanelWidth,
          AppSizes.workspacePanelMinWidth,
        );
      },
    );

    test(
      'aceite 31 — corrupção (D12): Left dobra ao padrão em silêncio, sem '
      'propagar erro',
      () async {
        repository.corrupted = true;
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        addTearDown(controller.dispose);

        await controller.ready;

        expect(controller.value, const EditorLayout());
        expect(controller.collapsedPaletteCategories.value, isEmpty);
        expect(controller.collapsedInspectorSections.value, isEmpty);
      },
    );

    test(
      'aceites 28/29 — o que uma sessão grava, a próxima carrega (refresh e '
      're-entrada)',
      () async {
        final first = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        await first.ready;

        first
          ..setLeftPanelWidth(430)
          ..collapseRightPanel();
        first.collapsedInspectorSections.value = {'Aparência'};
        first.dispose();
        await Future<void>.delayed(Duration.zero);

        final second = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        addTearDown(second.dispose);
        await second.ready;

        expect(second.value.leftPanelWidth, 430);
        expect(second.value.rightPanelCollapsed, isTrue);
        expect(second.collapsedInspectorSections.value, {'Aparência'});
      },
    );

    test(
      'gravação é debounced: várias mudanças em sequência resultam numa só '
      'escrita, com o valor final',
      () async {
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        addTearDown(controller.dispose);
        await controller.ready;

        controller
          ..setLeftPanelWidth(300)
          ..setLeftPanelWidth(310)
          ..setLeftPanelWidth(320);

        expect(repository.saveCount, 0);

        await Future<void>.delayed(const Duration(milliseconds: 450));

        expect(repository.saveCount, 1);
        expect(repository.stored?.leftPanelWidth, 320);
      },
    );

    test(
      'dispose com gravação pendente ainda grava — não espera o debounce '
      'que não vai mais rodar',
      () async {
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        await controller.ready;

        controller.setLeftPanelWidth(333);
        expect(repository.saveCount, 0);

        controller.dispose();
        await Future<void>.delayed(Duration.zero);

        expect(repository.saveCount, 1);
        expect(repository.stored?.leftPanelWidth, 333);
      },
    );

    test(
      'dispose sem gravação pendente não grava de novo',
      () async {
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        await controller.ready;
        await Future<void>.delayed(const Duration(milliseconds: 450));
        final savesBeforeDispose = repository.saveCount;

        controller.dispose();
        await Future<void>.delayed(Duration.zero);

        expect(repository.saveCount, savesBeforeDispose);
      },
    );

    test(
      'colapsar/expandir um grupo do Inspector agenda gravação (debounced)',
      () async {
        final controller = EditorLayoutController(
          getLayoutUseCase: getLayout,
          saveLayoutUseCase: saveLayout,
        );
        addTearDown(controller.dispose);
        await controller.ready;

        controller.collapsedInspectorSections.value = {'Aparência'};
        await Future<void>.delayed(const Duration(milliseconds: 450));

        expect(repository.saveCount, 1);
        expect(
          repository.stored?.collapsedInspectorSections,
          {'Aparência'},
        );
      },
    );
  });
}
