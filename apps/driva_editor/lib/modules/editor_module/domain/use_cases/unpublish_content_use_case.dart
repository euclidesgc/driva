import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';

class UnpublishContentUseCase {
  const UnpublishContentUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, Unit>> call(String id) => repository.unpublish(id);
}
