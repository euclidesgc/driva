import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

class SaveDraftUseCase {
  const SaveDraftUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, Unit>> call(ContentSpec content) {
    // Trava: nunca persistir spec que o próprio kernel rejeitaria.
    final revalidated = parseContentSpec(content.toJson());
    return revalidated.fold(
      (error) async => Left(ValidationFailure(error.message)),
      (_) => repository.saveDraft(content),
    );
  }
}
