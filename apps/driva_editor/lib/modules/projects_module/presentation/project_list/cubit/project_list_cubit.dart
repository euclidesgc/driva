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
  final DeleteProjectUseCase deleteProject;

  ProjectListCubit({
    required this.getProjects,
    required this.createProject,
    required this.updateProject,
    required this.deleteProject,
  }) : super(const ProjectListLoading());

  Future<void> load() async {
    emit(const ProjectListLoading());
    final result = await getProjects();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ProjectListError(failure: failure),
        (projects) => projects.isEmpty
            ? const ProjectListEmpty()
            : ProjectListLoaded(projects: projects),
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

  /// Atualiza e recarrega a lista no sucesso (título/capa podem ter mudado).
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
    if (result.isRight()) await load();
    return result;
  }

  /// Exclusão otimista: remove o card na hora sobre o `Loaded` atual (vira
  /// `Empty` ao esvaziar) e devolve o resultado. Em falha (ex.: 409 por
  /// `Restrict`), reconcilia com `load()` e devolve o `Left` para a UI
  /// avisar via snackbar com a mensagem da Failure.
  Future<Either<Failure, Unit>> delete(String id) async {
    final current = state;
    if (current is ProjectListLoaded) {
      final remaining = current.projects.where((p) => p.id != id).toList();
      emit(
        remaining.isEmpty
            ? const ProjectListEmpty()
            : ProjectListLoaded(projects: remaining),
      );
    }
    final result = await deleteProject(id);
    if (isClosed) return result;
    if (result.isLeft()) await load();
    return result;
  }
}
