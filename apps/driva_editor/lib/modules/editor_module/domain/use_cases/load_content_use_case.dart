import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';

class LoadContentUseCase {
  const LoadContentUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, LoadedContent>> call(String id) =>
      repository.loadContent(id);
}
