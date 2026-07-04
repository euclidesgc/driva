import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/contents_repository.dart';

/// Passa-fica de propósito: toda operação tem o seu use case (Apêndice D do
/// livro) — a forma previsível vale o boilerplate.
class DeleteContentUseCase {
  final ContentsRepository repository;
  const DeleteContentUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deleteContent(id);
}
