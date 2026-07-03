import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../pages_routes.dart';
import '../../domain/entities/page_summary.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/page_list_cubit.dart';

class PageListPage extends StatelessWidget {
  const PageListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => PageListCubit(
        getPages: getIt<GetPagesUseCase>(),
        createPage: getIt<CreatePageUseCase>(),
        deletePage: getIt<DeletePageUseCase>(),
      )..load(),
      child: const PageListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: AppWordmark(onTap: () => context.goNamed(PagesRoutes.pagesName)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nova página'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PageListCubit, PageListState>(
        builder: (context, state) {
          return switch (state) {
            PageListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            PageListEmpty() => _EmptyPages(
              onCreate: () => _showCreateDialog(context),
            ),
            final PageListError s => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<PageListCubit>().load(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            final PageListLoaded s => _PagesGrid(pages: s.pages),
          };
        },
      ),
    );
  }

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };

  Future<void> _showCreateDialog(BuildContext context) async {
    final cubit = context.read<PageListCubit>();
    final result = await showDialog<({String name, String screenTarget})>(
      context: context,
      builder: (_) => const _CreatePageDialog(),
    );
    if (result == null) return;

    final created = await cubit.create(
      name: result.name,
      screenTarget: result.screenTarget,
    );
    if (!context.mounted) return;
    created.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(failure)))),
      (page) => context.goNamed('editor', pathParameters: {'id': page.id}),
    );
  }
}

class _PagesGrid extends StatelessWidget {
  const _PagesGrid({required this.pages});

  final List<PageSummary> pages;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      padding: const EdgeInsets.all(24),
      maxCrossAxisExtent: 340,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [for (final page in pages) _PageCard(page: page)],
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.page});

  final PageSummary page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed('editor', pathParameters: {'id': page.id}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.web_asset, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      page.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir página',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Tela: ${page.screenTarget}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Atualizada em '
                '${page.updatedAt.day.toString().padLeft(2, '0')}/'
                '${page.updatedAt.month.toString().padLeft(2, '0')}/'
                '${page.updatedAt.year}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<PageListCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir página?'),
        content: Text('“${page.name}” será excluída. Essa ação não tem volta.'),
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
    if (confirmed ?? false) await cubit.delete(page.id);
  }
}

class _EmptyPages extends StatelessWidget {
  const _EmptyPages({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_customize_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Nenhuma página ainda.'),
          const SizedBox(height: 4),
          const Text('Crie a primeira e monte-a arrastando widgets.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Nova página'),
          ),
        ],
      ),
    );
  }
}

class _CreatePageDialog extends StatefulWidget {
  const _CreatePageDialog();

  @override
  State<_CreatePageDialog> createState() => _CreatePageDialogState();
}

class _CreatePageDialogState extends State<_CreatePageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _screenTarget = TextEditingController(text: 'home');

  @override
  void dispose() {
    _name.dispose();
    _screenTarget.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(
      context,
    ).pop((name: _name.text, screenTarget: _screenTarget.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova página'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da página',
                  hintText: 'Ex.: Home — vitrine',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _screenTarget,
                decoration: const InputDecoration(
                  labelText: 'Tela de destino',
                  hintText: 'Tela do app que recebe o fragmento',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe a tela.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
      ],
    );
  }
}
