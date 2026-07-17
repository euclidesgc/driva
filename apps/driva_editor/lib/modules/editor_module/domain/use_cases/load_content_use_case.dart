import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

class LoadContentUseCase {
  const LoadContentUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, ContentSpec>> call(String id) =>
      repository.loadContent(id);
}
