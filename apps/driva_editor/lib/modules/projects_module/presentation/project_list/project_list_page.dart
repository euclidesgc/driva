import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../../../injection.dart';
import '../../../contents_module/contents_module.dart';
import '../../../preferences_module/preferences_module.dart';
import '../../domain/entities/entities.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/project_list_cubit.dart';
import 'widgets/project_form_dialog.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => ProjectListCubit(
        getProjects: getIt<GetProjectsUseCase>(),
        createProject: getIt<CreateProjectUseCase>(),
        updateProject: getIt<UpdateProjectUseCase>(),
        deleteProject: getIt<DeleteProjectUseCase>(),
      )..load(),
      child: const ProjectListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppWordmark(),
        actions: [
          const ThemeModeButton(),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openCreateForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo projeto'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProjectListCubit, ProjectListState>(
        builder: (context, state) {
          return switch (state) {
            ProjectListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProjectListEmpty() => _EmptyProjects(
              onCreate: () => _openCreateForm(context),
            ),
            final ProjectListError s => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<ProjectListCubit>().load(),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            ),
            final ProjectListLoaded s => _ProjectsHome(projects: s.projects),
          };
        },
      ),
    );
  }

  static String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Nada encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => m,
    UnexpectedFailure() => 'Algo deu errado.',
  };

  static Future<void> _openCreateForm(BuildContext context) async {
    final cubit = context.read<ProjectListCubit>();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ProjectFormDialog(
        title: 'Novo projeto',
        onSubmit: (form) => cubit.create(
          title: form.title,
          description: form.description,
          image: form.image,
        ),
      ),
    );
    if (result != true || !context.mounted) return;
  }

  static Future<void> _openEditForm(
    BuildContext context,
    Project project,
  ) async {
    final cubit = context.read<ProjectListCubit>();
    await showDialog<bool>(
      context: context,
      builder: (_) => ProjectFormDialog(
        title: 'Editar projeto',
        initialTitle: project.title,
        initialDescription: project.description,
        initialImageUrl: project.imageUrl,
        onSubmit: (form) => cubit.update(
          project.id,
          title: form.title,
          description: form.description,
          image: form.image,
          removeImage: form.removeImage,
        ),
        onDelete: () => cubit.delete(project.id),
      ),
    );
  }
}

class _ProjectsHome extends StatelessWidget {
  const _ProjectsHome({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Projetos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${projects.length} ${projects.length == 1 ? 'projeto' : 'projetos'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 300 / 268,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) =>
                  _ProjectCard(project: projects[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final project = widget.project;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: _hovered
            ? (Matrix4.identity()..translateByDouble(0.0, -3.0, 0.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openProject(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProjectCover(project: project, hovered: _hovered),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 38,
                        child: Text(
                          project.description?.isNotEmpty == true
                              ? project.description!
                              : 'Sem descrição.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.inkSecondary,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: colors.border)),
                        ),
                        child: _ProjectFooterCounts(project: project),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openProject(BuildContext context) {
    context.goNamed(
      ContentsRoutes.projectDetailName,
      pathParameters: {'id': widget.project.id},
    );
  }
}

/// Contadores de "N categorias" / "N conteúdos" do rodapé do card.
///
/// O domain de Projeto (F3/F4) ainda não traz essas contagens — o backend
/// desta rodada não as devolve. Em vez de quebrar o layout ou inventar um
/// zero enganoso, o rodapé se oculta graciosamente quando a informação não
/// existe (nenhuma contagem hoje é sempre "ausente"; o `Project` do domain
/// não tem os campos). Quando o backend/domain passarem a expor
/// `categoryCount`/`contentCount`, é só trocar este widget.
class _ProjectFooterCounts extends StatelessWidget {
  const _ProjectFooterCounts({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    // Sem dado de contagem disponível ainda: mantemos o espaço do rodapé
    // (a linha divisória) mas sem números — evita "0 categorias" mentiroso.
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Text(
      'Atualizado ${_relativeUpdatedAt(project.updatedAt)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.inkMuted,
        fontSize: 12,
      ),
    );
  }

  String _relativeUpdatedAt(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'há ${diff.inHours} h';
    if (diff.inDays < 30) return 'há ${diff.inDays} d';
    return 'em ${updatedAt.day.toString().padLeft(2, '0')}/'
        '${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
  }
}

class _ProjectCover extends StatelessWidget {
  const _ProjectCover({required this.project, required this.hovered});

  final Project project;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(project.id);
    final initial = project.title.trim().isNotEmpty
        ? project.title.trim()[0].toUpperCase()
        : '?';

    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
            Image.network(
              project.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GradientTexture(gradient: gradient),
            )
          else
            _GradientTexture(gradient: gradient),
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Tooltip(
              message: 'Editar projeto',
              child: Semantics(
                button: true,
                label: 'Editar projeto ${project.title}',
                child: Material(
                  color: Colors.black.withValues(alpha: hovered ? 0.5 : 0.32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () =>
                        ProjectListPage._openEditForm(context, project),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientFor(String seed) {
    // Paleta fixa de gradientes (o protótipo alterna laranja/violeta); a
    // escolha por hash do id mantém o card com a mesma cor entre reloads.
    const palettes = [
      [Color(0xFFE07B39), Color(0xFFD96E2B)],
      [Color(0xFF7A5CF0), Color(0xFF5B3FD1)],
      [Color(0xFF2FA88E), Color(0xFF1F8A73)],
      [Color(0xFFD1476B), Color(0xFFB13457)],
    ];
    final index =
        seed.codeUnits.fold<int>(0, (sum, c) => sum + c) % palettes.length;
    return palettes[index];
  }
}

class _GradientTexture extends StatelessWidget {
  const _GradientTexture({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Opacity(
        opacity: 0.16,
        child: CustomPaint(painter: _GridTexturePainter()),
      ),
    );
  }
}

/// Textura de grid sutil sobre a capa do card (linhas finas 26x26, como o
/// protótipo).
class _GridTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 20),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.layers_outlined,
                  size: 28,
                  color: Color(0xFFE8602C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum projeto ainda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Crie seu primeiro projeto para organizar categorias e '
                'conteúdos do app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Novo projeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
