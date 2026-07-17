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
  const ProjectListEmpty({this.archivedCount = 0});
  final int archivedCount;
  @override
  List<Object?> get props => [archivedCount];
}

final class ProjectListLoaded extends ProjectListState {
  const ProjectListLoaded({required this.projects, this.archivedCount = 0});
  final List<Project> projects;
  final int archivedCount;
  @override
  List<Object?> get props => [projects, archivedCount];
}

final class ProjectListError extends ProjectListState {
  const ProjectListError({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
