import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../repositories/editor_repository.dart';

class SaveDraftUseCase {
  final EditorRepository repository;
  const SaveDraftUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(ContentSpec content) {
    // Regra de integridade: nunca persistir um spec que o próprio kernel
    // rejeitaria (o editor só produz árvores válidas; isto é a trava).
    final revalidated = parseContentSpec(content.toJson());
    return revalidated.fold(
      (error) async => Left(ValidationFailure(error.message)),
      (_) => repository.saveDraft(content),
    );
  }
}
