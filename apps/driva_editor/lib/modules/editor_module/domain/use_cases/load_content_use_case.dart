import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../repositories/editor_repository.dart';

class LoadContentUseCase {
  final EditorRepository repository;
  const LoadContentUseCase({required this.repository});

  Future<Either<Failure, ContentSpec>> call(String id) =>
      repository.loadContent(id);
}
