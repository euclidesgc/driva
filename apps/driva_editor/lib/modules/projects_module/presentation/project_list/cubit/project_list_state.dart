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
  final int archivedCount;
  const ProjectListEmpty({this.archivedCount = 0});
  @override
  List<Object?> get props => [archivedCount];
}

final class ProjectListLoaded extends ProjectListState {
  final List<Project> projects;
  final int archivedCount;
  const ProjectListLoaded({required this.projects, this.archivedCount = 0});
  @override
  List<Object?> get props => [projects, archivedCount];
}

final class ProjectListError extends ProjectListState {
  final Failure failure;
  const ProjectListError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
