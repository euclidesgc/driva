import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/contents_module/contents_routes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_load_failure_content.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_load_failure_view.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/projects_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditorCubit extends MockCubit<EditorState> implements EditorCubit {}

void main() {
  const projectId = 'proj_b';

  final project = Project(
    id: projectId,
    title: 'Vitrine de verão',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
    contentCount: 3,
    categoryCount: 1,
  );

  late _MockEditorCubit cubit;

  setUp(() {
    cubit = _MockEditorCubit();
    when(() => cubit.projectId).thenReturn(projectId);
    whenListen(
      cubit,
      const Stream<EditorState>.empty(),
      initialState: const EditorLoading(),
    );
  });

  late GoRouter router;

  Future<void> pumpFailure(
    WidgetTester tester, {
    required Failure failure,
    required Future<Either<Failure, Project>> projectFuture,
  }) {
    router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (context, state) => BlocProvider<EditorCubit>.value(
            value: cubit,
            child: EditorLoadFailureView(
              failure: failure,
              projectFuture: projectFuture,
            ),
          ),
        ),
        GoRoute(
          path: ContentsRoutes.projectDetail,
          name: ContentsRoutes.projectDetailName,
          builder: (context, state) => const Scaffold(body: Text('projeto')),
        ),
        GoRoute(
          path: ProjectsRoutes.projects,
          name: ProjectsRoutes.projectsName,
          builder: (context, state) => const Scaffold(body: Text('projetos')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  EditorLoadFailureContent shownContent(WidgetTester tester) =>
      tester.widget<EditorLoadFailureContent>(
        find.byType(EditorLoadFailureContent),
      );

  group('404 do conteúdo cruzado com o projeto da URL', () {
    testWidgets('projeto resolvido: a mensagem nomeia o projeto', (
      tester,
    ) async {
      await pumpFailure(
        tester,
        failure: const NotFoundFailure(),
        projectFuture: Future.value(Right(project)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não encontramos este conteúdo no projeto "${project.title}".',
        ),
        findsOneWidget,
      );
      expect(find.text('Voltar para o projeto'), findsOneWidget);

      await tester.tap(find.text('Voltar para o projeto'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/projects/$projectId',
      );
    });

    testWidgets('projeto inexistente: culpa o link e sai pela home', (
      tester,
    ) async {
      await pumpFailure(
        tester,
        failure: const NotFoundFailure(),
        projectFuture: Future.value(const Left(NotFoundFailure())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Este link aponta para um projeto que não existe.'),
        findsOneWidget,
      );
      expect(find.text('Ver meus projetos'), findsOneWidget);

      await tester.tap(find.text('Ver meus projetos'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
    });

    testWidgets('falha de rede no projeto: não afirma que ele não existe', (
      tester,
    ) async {
      await pumpFailure(
        tester,
        failure: const NotFoundFailure(),
        projectFuture: Future.value(const Left(NetworkFailure())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não encontramos este conteúdo.'), findsOneWidget);
      expect(find.textContaining('não existe'), findsNothing);
      expect(find.textContaining(project.title), findsNothing);
      expect(find.text('Ver meus projetos'), findsOneWidget);
    });

    testWidgets('as três saídas se distinguem por texto e por ícone', (
      tester,
    ) async {
      final messages = <String>{};
      final icons = <IconData>{};

      for (final projectResult in <Either<Failure, Project>>[
        Right(project),
        const Left(NotFoundFailure()),
        const Left(NetworkFailure()),
      ]) {
        await pumpFailure(
          tester,
          failure: const NotFoundFailure(),
          projectFuture: Future.value(projectResult),
        );
        await tester.pumpAndSettle();

        messages.add(shownContent(tester).message);
        icons.add(shownContent(tester).icon);
      }

      expect(messages, hasLength(3));
      expect(icons, hasLength(3));
    });

    testWidgets('enquanto o projeto não resolve, nenhuma das três aparece', (
      tester,
    ) async {
      final pending = Completer<Either<Failure, Project>>();
      addTearDown(() => pending.complete(Right(project)));

      await pumpFailure(
        tester,
        failure: const NotFoundFailure(),
        projectFuture: pending.future,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(EditorLoadFailureContent), findsNothing);
    });
  });

  group('as demais falhas não esperam o projeto', () {
    testWidgets('falha de rede no conteúdo mantém a mensagem de sempre', (
      tester,
    ) async {
      final pending = Completer<Either<Failure, Project>>();
      addTearDown(() => pending.complete(Right(project)));

      await pumpFailure(
        tester,
        failure: const NetworkFailure(),
        projectFuture: pending.future,
      );
      await tester.pump();

      expect(
        find.text('Sem conexão com o servidor. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('Voltar para o projeto'), findsOneWidget);
    });
  });
}
