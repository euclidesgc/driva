import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/network/project_scope.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/slug.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/category.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/contents_module/presentation/category_tree/category_tree.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/invalid_project_screen.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/category_form_dialog.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_form_dialog.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/content_panel_view.dart';
import 'package:driva_editor/modules/contents_module/presentation/project_detail/widgets/move_content_dialog.dart';
import 'package:driva_editor/modules/editor_module/editor_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

/// Único ponto que toca o `getIt`: monta os dois cubits (árvore e lista) E
/// estampa o [ProjectScope] com o `:id` da rota **antes** de criá-los, para
/// que toda chamada HTTP disparada por eles já saia com o `x-project-id`
/// certo.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    required this.projectFuture,
    super.key,
  });

  final String projectId;

  /// Busca o projeto (para o `title` do header) já disparada pelo
  /// [pageBuilder] — a única forma de chamar `getIt` nesta tela. Sobrevive a
  /// refresh porque é refeita a cada `pageBuilder` (rota), nunca depende de
  /// estado em memória de outra tela.
  final Future<Either<Failure, Project>> projectFuture;

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'];
    // Deep link malformado não é crash, é tela tratada.
    if (id == null || id.trim().isEmpty) return const InvalidProjectScreen();

    getIt<ProjectScope>().projectId = id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = CategoryTreeCubit(
              getCategories: getIt<GetCategoriesUseCase>(),
              createCategory: getIt<CreateCategoryUseCase>(),
              updateCategory: getIt<UpdateCategoryUseCase>(),
              deleteCategory: getIt<DeleteCategoryUseCase>(),
            );
            unawaited(cubit.load());
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = ContentListCubit(
              getContents: getIt<GetContentsUseCase>(),
              createContent: getIt<CreateContentUseCase>(),
              deleteContent: getIt<DeleteContentUseCase>(),
            );
            unawaited(cubit.load());
            return cubit;
          },
        ),
      ],
      child: ProjectDetailPage(
        projectId: id,
        projectFuture: getIt<GetProjectUseCase>()(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Project>>(
      future: projectFuture,
      builder: (context, snapshot) {
        final projectTitle = switch (snapshot.data) {
          Right(value: final project) => project.title,
          _ => projectId,
        };
        return AppShellSlot(
          crumbs: [
            const Crumb(
              label: 'Projetos',
              routeName: ProjectsRoutes.projectsName,
            ),
            Crumb(label: projectTitle),
          ],
          actions: [
            AppBarAction.filled(
              label: 'Novo conteúdo',
              icon: Icons.add,
              onPressed: () => _openContentForm(context),
            ),
          ],
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 272,
                  child: BlocBuilder<CategoryTreeCubit, CategoryTreeState>(
                    builder: (context, treeState) {
                      final categories = treeState is CategoryTreeLoaded
                          ? treeState.categories
                          : const <Category>[];
                      return CategoryTreeView(
                        contentCountByCategory: {
                          for (final category in categories)
                            category.id: category.contentCount,
                        },
                        allContentsCount: treeState is CategoryTreeLoaded
                            ? categories.fold<int>(
                                0,
                                (sum, category) => sum + category.contentCount,
                              )
                            : null,
                        onNewCategory: () => _openCategoryForm(context),
                        onEditCategory: (category) =>
                            _openCategoryForm(context, editing: category),
                        onDeleteCategory: (category) =>
                            _confirmDeleteCategory(context, category),
                        onMoveContent: (content, categoryId) => _moveContent(
                          context,
                          content,
                          categoryId,
                          offerUndo: true,
                        ),
                      );
                    },
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).extension<EditorColors>()!.border,
                ),
                Expanded(
                  child: BlocListener<CategoryTreeCubit, CategoryTreeState>(
                    listenWhen: (previous, current) =>
                        previous is CategoryTreeLoaded &&
                        current is CategoryTreeLoaded &&
                        previous.selectedCategoryId !=
                            current.selectedCategoryId,
                    listener: (context, state) {
                      final selected =
                          (state as CategoryTreeLoaded).selectedCategoryId;
                      unawaited(
                        context.read<ContentListCubit>().reloadWithFilter(
                          categoryId: () => selected,
                        ),
                      );
                    },
                    child: BlocBuilder<CategoryTreeCubit, CategoryTreeState>(
                      builder: (context, treeState) {
                        return ContentPanelView(
                          categoryLabel: _selectedCategoryLabel(treeState),
                          isAllContents:
                              treeState is CategoryTreeLoaded &&
                              treeState.selectedCategoryId == null,
                          categoryNameById: treeState is CategoryTreeLoaded
                              ? {
                                  for (final category in treeState.categories)
                                    category.id: category.name,
                                }
                              : const {},
                          onOpenContent: (content) => context.goNamed(
                            EditorRoutes.editorName,
                            pathParameters: {'id': content.id},
                          ),
                          onNewContent: () => _openContentForm(context),
                          onEditContent: (content) =>
                              _openContentForm(context, editing: content),
                          onMoveContent: (content) =>
                              _openMoveContentDialog(context, content),
                          onDeleteContent: (content) =>
                              _confirmDeleteContent(context, content),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _selectedCategoryLabel(CategoryTreeState state) {
    if (state is! CategoryTreeLoaded) return ' ';
    final selectedId = state.selectedCategoryId;
    if (selectedId == null) return 'Todos os conteúdos';
    for (final category in state.categories) {
      if (category.id == selectedId) return category.name;
    }
    return ' ';
  }

  static String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };

  static Future<void> _openCategoryForm(
    BuildContext context, {
    Category? editing,
  }) async {
    final treeCubit = context.read<CategoryTreeCubit>();
    final treeState = treeCubit.state;
    if (treeState is! CategoryTreeLoaded) return;

    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(
        title: editing == null ? 'Nova categoria' : 'Editar categoria',
        availableParents: treeState.categories,
        initialName: editing?.name,
        initialParentId: editing?.parentId,
        excludeIds: editing == null ? const {} : {editing.id},
      ),
    );
    if (result == null) return;

    final saved = editing == null
        ? await treeCubit.create(name: result.name, parentId: result.parentId)
        : await treeCubit.update(
            editing.id,
            name: result.name,
            parentId: () => result.parentId,
          );
    if (!context.mounted) return;
    saved.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(failure)))),
      (_) {},
    );
  }

  static Future<void> _confirmDeleteCategory(
    BuildContext context,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text(
          '"${category.name}" será excluída. Categorias com conteúdos ou '
          'subcategorias não podem ser excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final result = await context.read<CategoryTreeCubit>().delete(category.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(failure)))),
      (_) {},
    );
  }

  static Set<String> _knownSlugs(ContentListState state) => switch (state) {
    final ContentListLoaded s => s.contents.map((c) => c.slug).toSet(),
    _ => const <String>{},
  };

  static Future<void> _openContentForm(
    BuildContext context, {
    ContentSummary? editing,
    String? initialName,
    String? initialSlug,
    String? initialDescription,
    String? initialCategoryId,
    String? conflictMessage,
  }) async {
    final treeState = context.read<CategoryTreeCubit>().state;
    final categories = treeState is CategoryTreeLoaded
        ? treeState.categories
        : const <Category>[];
    final contentCubit = context.read<ContentListCubit>();
    final existingSlugs = _knownSlugs(contentCubit.state);

    final defaultCategoryId =
        initialCategoryId ??
        editing?.categoryId ??
        contentCubit.currentCategoryId;

    final result = await showDialog<ContentFormResult>(
      context: context,
      builder: (_) => ContentFormDialog(
        title: editing == null ? 'Novo conteúdo' : 'Editar conteúdo',
        saveLabel: editing == null ? 'Criar' : 'Salvar',
        categories: categories,
        existingSlugs: existingSlugs,
        initialName: initialName ?? editing?.name,
        initialSlug: initialSlug ?? editing?.slug,
        initialDescription: initialDescription ?? editing?.description,
        defaultCategoryId: defaultCategoryId,
        conflictMessage: conflictMessage,
      ),
    );
    if (result == null) return;

    final saved = editing == null
        ? await contentCubit.create(
            name: result.name,
            slug: result.slug,
            description: result.description,
            categoryId: result.categoryId,
          )
        : await getIt<UpdateContentUseCase>()(
            editing.id,
            name: result.name,
            slug: result.slug,
            description: result.description,
            categoryId: result.categoryId,
          );
    if (!context.mounted) return;

    saved.fold(
      (failure) {
        if (failure is ConflictFailure) {
          final suggestion =
              failure.suggestedSlug ??
              SlugUtil.suggestFree(result.slug, existingSlugs);
          unawaited(
            _openContentForm(
              context,
              editing: editing,
              initialName: result.name,
              initialSlug: suggestion,
              initialDescription: result.description,
              initialCategoryId: result.categoryId,
              conflictMessage:
                  'Slug já em uso neste projeto. Sugerimos "$suggestion".',
            ),
          );
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(failure))));
      },
      (content) {
        if (editing == null) {
          context.goNamed(
            EditorRoutes.editorName,
            pathParameters: {'id': content.id},
          );
        } else {
          unawaited(contentCubit.load());
        }
      },
    );
  }

  static Future<void> _confirmDeleteContent(
    BuildContext context,
    ContentSummary content,
  ) async {
    final cubit = context.read<ContentListCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conteúdo?'),
        content: Text(
          '"${content.name}" será excluído. Essa ação não tem volta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final result = await cubit.delete(content.id);
    if (!context.mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. Tente de novo.'),
        ),
      ),
      (_) {},
    );
  }

  /// Mover conteúdo entre categorias: dialog dedicado (seletor de categoria)
  /// → `_moveContent` (o mesmo caminho que o drag-and-drop usa) → `PUT
  /// /v1/contents/:id` com o novo `categoryId` (o backend já move e valida
  /// mesmo projeto). O dialog continua imediato, sem "Desfazer"
  /// (`offerUndo: false`); é o caminho acessível primário.
  static Future<void> _openMoveContentDialog(
    BuildContext context,
    ContentSummary content,
  ) async {
    final treeState = context.read<CategoryTreeCubit>().state;
    final categories = treeState is CategoryTreeLoaded
        ? treeState.categories
        : const <Category>[];

    final newCategoryId = await showDialog<String>(
      context: context,
      builder: (_) => MoveContentDialog(
        contentName: content.name,
        categories: categories,
        currentCategoryId: content.categoryId,
      ),
    );
    if (newCategoryId == null || !context.mounted) return;

    await _moveContent(context, content, newCategoryId, offerUndo: false);
  }

  /// Move `content` para `targetCategoryId` via `UpdateContentUseCase` — o
  /// caminho único que o dialog "mover" **e** o drag-and-drop da árvore
  /// compartilham. No sucesso, reflete a mudança **in-place**, sem refetch nem
  /// flash e **sem trocar a categoria selecionada**: o conteúdo some da lista
  /// da categoria de origem (à direita) e os contadores da árvore ajustam
  /// (-1 origem / +1 destino). A tela continua onde o usuário estava.
  static Future<void> _moveContent(
    BuildContext context,
    ContentSummary content,
    String targetCategoryId, {
    required bool offerUndo,
  }) async {
    if (targetCategoryId == content.categoryId) return;

    final saved = await getIt<UpdateContentUseCase>()(
      content.id,
      categoryId: targetCategoryId,
    );
    if (!context.mounted) return;
    saved.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(failure)))),
      (_) {
        context.read<ContentListCubit>().reflectMovedOut(content.id);
        context.read<CategoryTreeCubit>().applyContentMove(
          fromCategoryId: content.categoryId,
          toCategoryId: targetCategoryId,
        );
      },
    );
  }
}
