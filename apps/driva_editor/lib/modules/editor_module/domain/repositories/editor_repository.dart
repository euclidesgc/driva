import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';

/// Contrato do editor: carregar o spec completo e salvar o rascunho.
/// `ContentSpec` é entidade do kernel (Dart puro) — permitida no domain.
abstract interface class EditorRepository {
  Future<Either<Failure, ContentSpec>> loadContent(String id);

  Future<Either<Failure, Unit>> saveDraft(ContentSpec content);
}
