part of 'archived_projects_cubit.dart';

sealed class ArchivedProjectsState extends Equatable {
  const ArchivedProjectsState();
  @override
  List<Object?> get props => [];
}

final class ArchivedProjectsLoading extends ArchivedProjectsState {
  const ArchivedProjectsLoading();
}

/// Nenhum projeto arquivado: tem UX própria.
final class ArchivedProjectsEmpty extends ArchivedProjectsState {
  const ArchivedProjectsEmpty();
}

final class ArchivedProjectsLoaded extends ArchivedProjectsState {
  const ArchivedProjectsLoaded({required this.projects});
  final List<Project> projects;
  @override
  List<Object?> get props => [projects];
}

final class ArchivedProjectsError extends ArchivedProjectsState {
  const ArchivedProjectsError({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
