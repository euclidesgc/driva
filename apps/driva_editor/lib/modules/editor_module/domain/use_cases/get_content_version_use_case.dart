import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetContentVersionUseCase {
  const GetContentVersionUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, LoadedContentVersion>> call(
    String id,
    int version,
  ) => repository.getVersion(id, version);
}
