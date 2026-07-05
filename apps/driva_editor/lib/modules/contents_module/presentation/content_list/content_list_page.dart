import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/util/slug.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../contents_routes.dart';
import '../../domain/entities/content_summary.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/content_list_cubit.dart';

typedef _ContentFormResult = ({String name, String slug, String? description});

class ContentListPage extends StatelessWidget {
  const ContentListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => ContentListCubit(
        getContents: getIt<GetContentsUseCase>(),
        createContent: getIt<CreateContentUseCase>(),
        deleteContent: getIt<DeleteContentUseCase>(),
      )..load(),
      child: const ContentListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: AppWordmark(
          onTap: () => context.goNamed(ContentsRoutes.contentsName),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo conteúdo'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ContentListCubit, ContentListState>(
        builder: (context, state) {
          return switch (state) {
            ContentListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ContentListEmpty() => _EmptyContents(
              onCreate: () => _showCreateDialog(context),
            ),
            final ContentListError s => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<ContentListCubit>().load(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            final ContentListLoaded s => _ContentsGrid(contents: s.contents),
          };
        },
      ),
    );
  }

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };

  Set<String> _knownSlugs(ContentListState state) => switch (state) {
    final ContentListLoaded s => s.contents.map((c) => c.slug).toSet(),
    _ => const <String>{},
  };

  Future<void> _showCreateDialog(
    BuildContext context, {
    String? initialName,
    String? initialSlug,
    String? initialDescription,
    String? conflictMessage,
  }) async {
    final cubit = context.read<ContentListCubit>();
    final existingSlugs = _knownSlugs(cubit.state);

    final result = await showDialog<_ContentFormResult>(
      context: context,
      builder: (_) => _CreateContentDialog(
        existingSlugs: existingSlugs,
        initialName: initialName,
        initialSlug: initialSlug,
        initialDescription: initialDescription,
        conflictMessage: conflictMessage,
      ),
    );
    if (result == null) return;

    final created = await cubit.create(
      name: result.name,
      slug: result.slug,
      description: result.description,
    );
    if (!context.mounted) return;
    created.fold(
      (failure) {
        // Slug em uso: reabre o formulário já com a sugestão livre e explica.
        if (failure is ConflictFailure) {
          final suggestion =
              failure.suggestedSlug ??
              SlugUtil.suggestFree(result.slug, existingSlugs);
          _showCreateDialog(
            context,
            initialName: result.name,
            initialSlug: suggestion,
            initialDescription: result.description,
            conflictMessage:
                'Slug já em uso neste projeto. Sugerimos "$suggestion".',
          );
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(failure))));
      },
      (content) =>
          context.goNamed('editor', pathParameters: {'id': content.id}),
    );
  }
}

class _ContentsGrid extends StatelessWidget {
  const _ContentsGrid({required this.contents});

  final List<ContentSummary> contents;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      padding: const EdgeInsets.all(24),
      maxCrossAxisExtent: 360,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        for (final content in contents) _ContentCard(content: content),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.content});

  final ContentSummary content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.goNamed('editor', pathParameters: {'id': content.id}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _SlugBadge(slug: content.slug)),
                  IconButton(
                    tooltip: 'Excluir conteúdo',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (content.description != null &&
                  content.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  content.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              _SupportId(id: content.id),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ContentListCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conteúdo?'),
        content: Text(
          '“${content.name}” será excluído. Essa ação não tem volta.',
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

/// Slug em destaque: ícone + rótulo textual "slug" (a cor não é o único sinal).
class _SlugBadge extends StatelessWidget {
  const _SlugBadge({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Slug do conteúdo: $slug',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                slug,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportId extends StatelessWidget {
  const _SupportId({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'ID de suporte — use ao reportar um problema.',
      child: Semantics(
        label: 'ID de suporte: $id',
        child: Row(
          children: [
            Icon(
              Icons.numbers,
              size: 13,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'ID de suporte: $id',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContents extends StatelessWidget {
  const _EmptyContents({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_customize_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Nenhum conteúdo ainda. Crie o primeiro.'),
          const SizedBox(height: 4),
          const Text('Monte-o arrastando widgets no editor.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo conteúdo'),
          ),
        ],
      ),
    );
  }
}

class _CreateContentDialog extends StatefulWidget {
  const _CreateContentDialog({
    required this.existingSlugs,
    this.initialName,
    this.initialSlug,
    this.initialDescription,
    this.conflictMessage,
  });

  final Set<String> existingSlugs;
  final String? initialName;
  final String? initialSlug;
  final String? initialDescription;
  final String? conflictMessage;

  @override
  State<_CreateContentDialog> createState() => _CreateContentDialogState();
}

class _CreateContentDialogState extends State<_CreateContentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _description;

  /// Enquanto o usuário não editar o slug à mão, ele acompanha o nome.
  bool _slugTouched = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _slug = TextEditingController(text: widget.initialSlug ?? '');
    _description = TextEditingController(text: widget.initialDescription ?? '');
    // Reaberto com uma sugestão (pós-conflito): o slug já vem "fixado".
    _slugTouched = (widget.initialSlug ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_slugTouched) return;
    setState(() {
      _slug.text = SlugUtil.suggestFree(
        SlugUtil.slugify(value),
        widget.existingSlugs,
      );
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _description.text.trim();
    Navigator.of(context).pop((
      name: _name.text,
      slug: _slug.text.trim(),
      description: description.isEmpty ? null : description,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Novo conteúdo'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.conflictMessage != null) ...[
                _ConflictBanner(message: widget.conflictMessage!),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Home — vitrine',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe o nome.' : null,
                onChanged: _onNameChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Slug — referência no código',
                  prefixIcon: Icon(Icons.tag),
                  helperText:
                      'O slug é sua referência no código; mudá-lo depois '
                      'quebra apps que já o usam.',
                  helperMaxLines: 2,
                ),
                onChanged: (_) => _slugTouched = true,
                validator: (value) {
                  final slug = (value ?? '').trim();
                  if (slug.isEmpty) return 'Informe o slug.';
                  if (!SlugUtil.isValid(slug)) {
                    return 'Use letras minúsculas, números e hifens '
                        '(começando por letra).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Para que serve este conteúdo?',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 4),
              Text(
                'ID de suporte é gerado pelo servidor após criar.',
                style: theme.textTheme.bodySmall,
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

/// Aviso de slug em uso: ícone + texto (a cor não é o único sinal).
class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Aviso: $message',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
