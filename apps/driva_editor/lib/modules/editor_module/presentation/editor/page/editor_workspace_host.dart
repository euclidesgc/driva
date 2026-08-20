import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_workspace.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:sdui_flutter/sdui_flutter.dart';

/// Instala o soquete do modo de comparação acima do workspace e cria o cubit
/// que vive enquanto a página vive — trocar de versão no histórico não pode
/// recriar o estado do modo.
///
/// Quando os dois use cases de versão não chegam, o workspace monta sem o
/// soquete: sem eles o botão de histórico já nasce desabilitado, então não
/// há por onde entrar no modo.
class EditorWorkspaceHost extends StatefulWidget {
  const EditorWorkspaceHost({
    required this.projectFuture,
    required this.layoutController,
    this.imageUrlResolver,
    this.getContentVersionsUseCase,
    this.getContentVersionUseCase,
    this.getContentCheckpointsUseCase,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;
  final EditorLayoutController layoutController;
  final SduiImageUrlResolver? imageUrlResolver;
  final GetContentVersionsUseCase? getContentVersionsUseCase;
  final GetContentVersionUseCase? getContentVersionUseCase;
  final GetContentCheckpointsUseCase? getContentCheckpointsUseCase;

  @override
  State<EditorWorkspaceHost> createState() => _EditorWorkspaceHostState();
}

class _EditorWorkspaceHostState extends State<EditorWorkspaceHost> {
  VersionCompareModeCubit? _compareMode;

  @override
  void initState() {
    super.initState();
    final versions = widget.getContentVersionsUseCase;
    final version = widget.getContentVersionUseCase;
    if (versions == null || version == null) return;
    _compareMode = VersionCompareModeCubit(
      getContentVersionUseCase: version,
      getContentVersionsUseCase: versions,
      editorCubit: context.read<EditorCubit>(),
    );
  }

  @override
  void dispose() {
    unawaited(_compareMode?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = EditorWorkspace(
      projectFuture: widget.projectFuture,
      imageUrlResolver: widget.imageUrlResolver,
      layoutController: widget.layoutController,
      getContentVersionsUseCase: widget.getContentVersionsUseCase,
      getContentVersionUseCase: widget.getContentVersionUseCase,
      getContentCheckpointsUseCase: widget.getContentCheckpointsUseCase,
    );
    final mode = _compareMode;
    if (mode == null) return workspace;
    return VersionCompareModeScope(cubit: mode, child: workspace);
  }
}
