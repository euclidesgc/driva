import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../repositories/contents_repository.dart';

class DeleteContentUseCase {
  final ContentsRepository repository;
  const DeleteContentUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id) => repository.deleteContent(id);
}
