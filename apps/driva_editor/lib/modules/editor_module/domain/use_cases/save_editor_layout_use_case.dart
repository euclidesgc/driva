import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:fpdart/fpdart.dart';

class SaveEditorLayoutUseCase {
  const SaveEditorLayoutUseCase({required this.repository});
  final EditorLayoutRepository repository;

  Future<Either<Failure, Unit>> call(EditorLayoutSnapshot layout) =>
      repository.saveLayout(layout);
}
