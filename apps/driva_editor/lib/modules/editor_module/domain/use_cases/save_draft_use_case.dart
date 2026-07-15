import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../repositories/editor_repository.dart';

class SaveDraftUseCase {
  final EditorRepository repository;
  const SaveDraftUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(ContentSpec content) {
    // Trava: nunca persistir spec que o próprio kernel rejeitaria.
    final revalidated = parseContentSpec(content.toJson());
    return revalidated.fold(
      (error) async => Left(ValidationFailure(error.message)),
      (_) => repository.saveDraft(content),
    );
  }
}
