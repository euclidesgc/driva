import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/contents_module/contents_routes.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_node.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/cubit/category_tree_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/project_detail_page.dart';
import 'package:driva_editor/modules/editor_module/editor_routes.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryTreeCubit extends MockCubit<CategoryTreeState>
    implements CategoryTreeCubit {}

class _MockContentListCubit extends MockCubit<ContentListState>
    implements ContentListCubit {}

void main() {
  const projectId = 'proj_b';

  final project = Project(
    id: projectId,
    title: 'Vitrine de verão',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
    contentCount: 1,
    categoryCount: 1,
  );

  const category = Category(
    id: 'cat_1',
    projectId: projectId,
    name: 'Geral',
    contentCount: 1,
  );

  final existing = ContentSummary(
    id: 'ct_ja_existente',
    name: 'Home',
    slug: 'home',
    categoryId: category.id,
    updatedAt: DateTime.utc(2026, 8),
    publishedAt: null,
    hasUnpublishedChanges: true,
  );

  final created = ContentSummary(
    id: 'ct_recem_criado',
    name: 'Promoções',
    slug: 'promocoes',
    categoryId: category.id,
    updatedAt: DateTime.utc(2026, 8),
    publishedAt: null,
    hasUnpublishedChanges: true,
  );

  late _MockCategoryTreeCubit treeCubit;
  late _MockContentListCubit contentCubit;
  late GoRouter router;
  late List<Map<String, String>> editorParams;

  setUp(() {
    treeCubit = _MockCategoryTreeCubit();
    contentCubit = _MockContentListCubit();
    editorParams = [];

    whenListen(
      treeCubit,
      const Stream<CategoryTreeState>.empty(),
      initialState: CategoryTreeLoaded(
        categories: const [category],
        forest: CategoryNode.buildForest(const [category]),
        selectedCategoryId: null,
        collapsedIds: const {},
      ),
    );
    when(() => contentCubit.currentSort).thenReturn(ContentSort.updatedAt);
    when(() => contentCubit.currentOrder).thenReturn(ContentSortOrder.desc);
    when(() => contentCubit.currentCategoryId).thenReturn(category.id);
  });

  Future<void> pumpProjectDetail(
    WidgetTester tester, {
    required ContentListState contentState,
  }) async {
    whenListen(
      contentCubit,
      const Stream<ContentListState>.empty(),
      initialState: contentState,
    );

    router = GoRouter(
      initialLocation: '/projects/$projectId',
      routes: [
        GoRoute(
          path: ContentsRoutes.projectDetail,
          name: ContentsRoutes.projectDetailName,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<CategoryTreeCubit>.value(value: treeCubit),
              BlocProvider<ContentListCubit>.value(value: contentCubit),
            ],
            child: ProjectDetailPage(
              projectId: projectId,
              projectFuture: Future.value(Right(project)),
            ),
          ),
        ),
        GoRoute(
          path: EditorRoutes.editor,
          name: EditorRoutes.editorName,
          builder: (context, state) {
            editorParams.add(state.pathParameters);
            return const Scaffold(body: Text('editor'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  group('os dois caminhos da tela de projeto para o editor', () {
    testWidgets('abrir conteúdo da lista leva projeto e conteúdo no path', (
      tester,
    ) async {
      await pumpProjectDetail(
        tester,
        contentState: ContentListLoaded(contents: [existing]),
      );

      await tester.tap(find.text(existing.name).first);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/projects/$projectId/contents/${existing.id}/edit',
      );
      expect(editorParams.single, {
        'projectId': projectId,
        'id': existing.id,
      });
    });

    testWidgets('conteúdo recém-criado cai no editor com os dois params', (
      tester,
    ) async {
      when(
        () => contentCubit.create(
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          description: any(named: 'description'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right(created));

      await pumpProjectDetail(tester, contentState: const ContentListEmpty());

      await tester.tap(find.text('Novo conteúdo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        created.name,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/projects/$projectId/contents/${created.id}/edit',
      );
      expect(editorParams.single, {'projectId': projectId, 'id': created.id});
    });
  });
}
