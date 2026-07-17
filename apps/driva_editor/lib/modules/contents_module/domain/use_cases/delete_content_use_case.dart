import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/contents_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteContentUseCase {
  const DeleteContentUseCase({required this.repository});
  final ContentsRepository repository;

  Future<Either<Failure, Unit>> call(String id) => repository.deleteContent(id);
}
