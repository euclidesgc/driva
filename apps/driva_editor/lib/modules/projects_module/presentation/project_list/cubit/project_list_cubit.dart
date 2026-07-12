import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'project_list_state.dart';

class ProjectListCubit extends Cubit<ProjectListState> {
  final GetProjectsUseCase getProjects;
  final CreateProjectUseCase createProject;
  final UpdateProjectUseCase updateProject;
  final ArchiveProjectUseCase archiveProject;

  ProjectListCubit({
    required this.getProjects,
    required this.createProject,
    required this.updateProject,
    required this.archiveProject,
  }) : super(const ProjectListLoading());

  /// Carrega a home (ativos) e a contagem de arquivados (para o link
  /// "Arquivados (N)" do header) em paralelo.
  Future<void> load() async {
    emit(const ProjectListLoading());
    final results = await Future.wait([
      getProjects(),
      getProjects(archived: true),
    ]);
    if (isClosed) return;
    final activeResult = results[0];
    final archivedResult = results[1];
    final archivedCount = archivedResult.fold((_) => 0, (p) => p.length);
    emit(
      activeResult.fold(
        (failure) => ProjectListError(failure: failure),
        (projects) => projects.isEmpty
            ? ProjectListEmpty(archivedCount: archivedCount)
            : ProjectListLoaded(
                projects: projects,
                archivedCount: archivedCount,
              ),
      ),
    );
  }

  /// Cria e recarrega a lista no sucesso (o card novo precisa aparecer na
  /// home). No erro, a UI trata pelo `Left` sem tocar o estado atual.
  Future<Either<Failure, Project>> create({
    required String title,
    String? description,
    ProjectImageInput? image,
  }) async {
    final result = await createProject(
      title: title,
      description: description,
      image: image,
    );
    if (isClosed) return result;
    if (result.isRight()) await load();
    return result;
  }

  /// Atualiza e reflete a mudança **só no card afetado** — troca aquele
  /// `Project` na lista `Loaded` atual pelo retornado (título/capa novos, com
  /// `imageUrl` já cache-busted), sem emitir `Loading` nem refetchar a lista
  /// (nada de rebuild/flash da home inteira). No erro, não toca o estado (a UI
  /// trata pelo `Left`). Estado fora de `Loaded` no sucesso (raro) reconcilia
  /// com `load()`.
  Future<Either<Failure, Project>> update(
    String id, {
    String? title,
    String? description,
    ProjectImageInput? image,
    bool removeImage = false,
  }) async {
    final result = await updateProject(
      id,
      title: title,
      description: description,
      image: image,
      removeImage: removeImage,
    );
    if (isClosed) return result;
    final current = state;
    if (current is ProjectListLoaded) {
      result.map((updated) {
        emit(
          ProjectListLoaded(
            projects: [
              for (final p in current.projects)
                p.id == updated.id ? updated : p,
            ],
            archivedCount: current.archivedCount,
          ),
        );
      });
    } else if (result.isRight()) {
      await load();
    }
    return result;
  }

  /// Arquivamento otimista (exclusão lógica): remove o card da home na hora
  /// sobre o `Loaded` atual (vira `Empty` ao esvaziar) e devolve o
  /// resultado. Em falha, reconcilia com `load()` e devolve o `Left` para a
  /// UI avisar via snackbar com a mensagem da Failure.
  Future<Either<Failure, Project>> archive(String id) async {
    final current = state;
    if (current is ProjectListLoaded) {
      final remaining = current.projects.where((p) => p.id != id).toList();
      final archivedCount = current.archivedCount + 1;
      emit(
        remaining.isEmpty
            ? ProjectListEmpty(archivedCount: archivedCount)
            : ProjectListLoaded(
                projects: remaining,
                archivedCount: archivedCount,
              ),
      );
    }
    final result = await archiveProject(id);
    if (isClosed) return result;
    if (result.isLeft()) await load();
    return result;
  }
}
