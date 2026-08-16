import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetEditorLayoutUseCase {
  const GetEditorLayoutUseCase({required this.repository});
  final EditorLayoutRepository repository;

  Future<Either<Failure, EditorLayoutSnapshot>> call() =>
      repository.getLayout();
}
