import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../repositories/editor_repository.dart';

/// Passa-fica de propósito (Apêndice D do livro): a forma previsível vale.
class LoadPageUseCase {
  final EditorRepository repository;
  const LoadPageUseCase({required this.repository});

  Future<Either<Failure, PageSpec>> call(String id) => repository.loadPage(id);
}
