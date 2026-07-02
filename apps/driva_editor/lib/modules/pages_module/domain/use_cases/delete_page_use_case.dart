import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/pages_repository.dart';

/// Passa-fica de propósito: toda operação tem o seu use case (Apêndice D do
/// livro) — a forma previsível vale o boilerplate.
class DeletePageUseCase {
  final PagesRepository repository;
  const DeletePageUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deletePage(id);
}
