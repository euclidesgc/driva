import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'archived_projects_state.dart';

class ArchivedProjectsCubit extends Cubit<ArchivedProjectsState> {
  final GetProjectsUseCase getProjects;
  final UnarchiveProjectUseCase unarchiveProject;
  final DeleteProjectUseCase deleteProject;

  ArchivedProjectsCubit({
    required this.getProjects,
    required this.unarchiveProject,
    required this.deleteProject,
  }) : super(const ArchivedProjectsLoading());

  Future<void> load() async {
    emit(const ArchivedProjectsLoading());
    final result = await getProjects(archived: true);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ArchivedProjectsError(failure: failure),
        (projects) => projects.isEmpty
            ? const ArchivedProjectsEmpty()
            : ArchivedProjectsLoaded(projects: projects),
      ),
    );
  }

  /// Restaura: remove o card da lista de arquivados na hora (otimista) e
  /// devolve o resultado para a UI eventualmente navegar de volta à home.
  /// Em falha, reconcilia com `load()`.
  Future<Either<Failure, Project>> restore(String id) async {
    final current = state;
    if (current is ArchivedProjectsLoaded) {
      final remaining = current.projects.where((p) => p.id != id).toList();
      emit(
        remaining.isEmpty
            ? const ArchivedProjectsEmpty()
            : ArchivedProjectsLoaded(projects: remaining),
      );
    }
    final result = await unarchiveProject(id);
    if (isClosed) return result;
    if (result.isLeft()) await load();
    return result;
  }

  /// Exclusão definitiva (cascade total, sem volta). Remove o card na hora
  /// sobre o `Loaded` atual; em falha, reconcilia com `load()`.
  Future<Either<Failure, Unit>> deleteForever(String id) async {
    final current = state;
    if (current is ArchivedProjectsLoaded) {
      final remaining = current.projects.where((p) => p.id != id).toList();
      emit(
        remaining.isEmpty
            ? const ArchivedProjectsEmpty()
            : ArchivedProjectsLoaded(projects: remaining),
      );
    }
    final result = await deleteProject(id);
    if (isClosed) return result;
    if (result.isLeft()) await load();
    return result;
  }
}
