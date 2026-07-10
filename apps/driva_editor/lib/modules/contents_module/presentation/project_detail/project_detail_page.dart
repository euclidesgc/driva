import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/network/project_scope.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../../../core/util/slug.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../../editor_module/editor_module.dart';
import '../../../preferences_module/preferences_module.dart';
import '../../../projects_module/projects_module.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/use_cases/use_cases.dart';
import '../category_tree/category_tree.dart';
import '../content_list/cubit/content_list_cubit.dart';
import 'widgets/category_form_dialog.dart';
import 'widgets/content_form_dialog.dart';
import 'widgets/content_panel_view.dart';

/// A tela do projeto: header (voltar a Projetos + nome do projeto) + árvore
/// de categorias à esquerda + painel de conteúdos à direita. Fiel ao
/// `.dc.html` (`isProject`).
///
/// Único ponto que toca o `getIt`: monta os dois cubits (árvore e lista) E
/// estampa o [ProjectScope] com o `:id` da rota **antes** de criá-los, para
/// que toda chamada HTTP disparada por eles já saia com o `x-project-id`
/// certo.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'];
    // Deep link malformado não é crash, é tela tratada.
    if (id == null || id.trim().isEmpty) return const _InvalidProjectScreen();

    getIt<ProjectScope>().set(id);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CategoryTreeCubit(
            getCategories: getIt<GetCategoriesUseCase>(),
            createCategory: getIt<CreateCategoryUseCase>(),
            updateCategory: getIt<UpdateCategoryUseCase>(),
            deleteCategory: getIt<DeleteCategoryUseCase>(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => ContentListCubit(
            getContents: getIt<GetContentsUseCase>(),
            createContent: getIt<CreateContentUseCase>(),
            deleteContent: getIt<DeleteContentUseCase>(),
          )..load(),
        ),
      ],
      child: ProjectDetailPage(projectId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _ProjectDetailHeader(projectId: projectId),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 272,
                  child: CategoryTreeView(
                    // TODO(P3): contagem por categoria e "Não categorizados"
                    // dependem de um agregado que o backend ainda não expõe
                    // (`GET /v1/contents` não devolve `count` por nó); a
                    // árvore funciona sem os números.
                    contentCountByCategory: const {},
                    uncategorizedCount: null,
                    onNewCategory: () => _openCategoryForm(context),
                    onEditCategory: (category) =>
                        _openCategoryForm(context, editing: category),
                    onDeleteCategory: (category) =>
                        _confirmDeleteCategory(context, category),
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
                      context.read<ContentListCubit>().reloadWithFilter(
                        categoryId: () => selected,
                      );
                    },
                    child: BlocBuilder<CategoryTreeCubit, CategoryTreeState>(
                      builder: (context, treeState) {
                        return ContentPanelView(
                          categoryLabel: _selectedCategoryLabel(treeState),
                          onOpenContent: (content) => context.goNamed(
                            EditorRoutes.editorName,
                            pathParameters: {'id': content.id},
                          ),
                          onNewContent: () => _openContentForm(context),
                          onEditContent: (content) =>
                              _openContentForm(context, editing: content),
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
        ],
      ),
    );
  }

  String _selectedCategoryLabel(CategoryTreeState state) {
    if (state is! CategoryTreeLoaded) return ' ';
    final selectedId = state.selectedCategoryId;
    if (selectedId == null) return 'Não categorizados';
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

    final Either<Failure, ContentSummary> saved = editing == null
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
          _openContentForm(
            context,
            editing: editing,
            initialName: result.name,
            initialSlug: suggestion,
            initialDescription: result.description,
            initialCategoryId: result.categoryId,
            conflictMessage:
                'Slug já em uso neste projeto. Sugerimos "$suggestion".',
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
          contentCubit.load();
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
}

class _ProjectDetailHeader extends StatelessWidget {
  const _ProjectDetailHeader({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Voltar aos projetos',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
            ),
          ),
          AppWordmark(
            onTap: () => context.goNamed(ProjectsRoutes.projectsName),
          ),
          const SizedBox(width: 4),
          Expanded(child: _ProjectTitle(projectId: projectId)),
          const ThemeModeButton(),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: () => ProjectDetailPage._openContentForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Novo conteúdo'),
          ),
        ],
      ),
    );
  }
}

/// Nome do projeto no header.
///
/// TODO(infra/P3): `projects_module` não exporta `GetProjectUseCase` pelo
/// barrel público (só rota + injection + a página de lista) — a
/// `presentation` de `contents_module` não pode alcançar o `domain` de outro
/// módulo por fora dele (regra "só o barrel público"). Até o barrel expor um
/// jeito de ler um projeto por id, o header mostra o `id` como referência.
class _ProjectTitle extends StatelessWidget {
  const _ProjectTitle({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        projectId,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _InvalidProjectScreen extends StatelessWidget {
  const _InvalidProjectScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Link de projeto inválido.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
              child: const Text('Voltar aos projetos'),
            ),
          ],
        ),
      ),
    );
  }
}
