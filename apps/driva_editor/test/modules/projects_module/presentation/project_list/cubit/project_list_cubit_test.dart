import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/cubit/project_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetProjects extends Mock implements GetProjectsUseCase {}

class _MockCreateProject extends Mock implements CreateProjectUseCase {}

class _MockUpdateProject extends Mock implements UpdateProjectUseCase {}

class _MockArchiveProject extends Mock implements ArchiveProjectUseCase {}

void main() {
  late _MockGetProjects getProjects;
  late _MockCreateProject createProject;
  late _MockUpdateProject updateProject;
  late _MockArchiveProject archiveProject;

  setUp(() {
    getProjects = _MockGetProjects();
    createProject = _MockCreateProject();
    updateProject = _MockUpdateProject();
    archiveProject = _MockArchiveProject();
  });

  ProjectListCubit build() => ProjectListCubit(
    getProjects: getProjects,
    createProject: createProject,
    updateProject: updateProject,
    archiveProject: archiveProject,
  );

  final at = DateTime.utc(2026, 7, 11);
  Project proj(String id, {String? imageUrl, DateTime? updatedAt}) => Project(
    id: id,
    title: 'P$id',
    createdAt: at,
    updatedAt: updatedAt ?? at,
    contentCount: 0,
    categoryCount: 1,
    imageUrl: imageUrl,
  );

  group('update (reflexo isolado, sem rebuild da lista)', () {
    final updated = proj(
      '1',
      imageUrl: 'https://api/v1/projects/1/image?v=2',
      updatedAt: DateTime.utc(2026, 7, 12),
    );

    blocTest<ProjectListCubit, ProjectListState>(
      'troca só o card afetado — uma emissão Loaded, sem Loading nem refetch',
      build: build,
      seed: () =>
          ProjectListLoaded(projects: [proj('1'), proj('2')], archivedCount: 3),
      setUp: () => when(
        () => updateProject(
          '1',
          title: 'Novo',
          description: null,
          image: null,
          removeImage: false,
        ),
      ).thenAnswer((_) async => Right(updated)),
      act: (cubit) => cubit.update('1', title: 'Novo'),
      expect: () => [
        ProjectListLoaded(projects: [updated, proj('2')], archivedCount: 3),
      ],
      verify: (_) => verifyNever(() => getProjects()),
    );

    blocTest<ProjectListCubit, ProjectListState>(
      'no erro não toca o estado (UI trata pelo Left)',
      build: build,
      seed: () => ProjectListLoaded(projects: [proj('1')], archivedCount: 0),
      setUp: () => when(
        () => updateProject(
          '1',
          title: 'Novo',
          description: null,
          image: null,
          removeImage: false,
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.update('1', title: 'Novo'),
      expect: () => const <ProjectListState>[],
    );
  });
}
