part of 'project_list_cubit.dart';

sealed class ProjectListState extends Equatable {
  const ProjectListState();
  @override
  List<Object?> get props => [];
}

final class ProjectListLoading extends ProjectListState {
  const ProjectListLoading();
}

/// Nenhum projeto ainda: tem UX própria ("crie seu primeiro projeto").
final class ProjectListEmpty extends ProjectListState {
  const ProjectListEmpty();
}

final class ProjectListLoaded extends ProjectListState {
  final List<Project> projects;
  const ProjectListLoaded({required this.projects});
  @override
  List<Object?> get props => [projects];
}

final class ProjectListError extends ProjectListState {
  final Failure failure;
  const ProjectListError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
