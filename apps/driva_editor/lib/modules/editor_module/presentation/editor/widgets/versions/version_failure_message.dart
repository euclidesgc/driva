import 'package:driva_editor/core/error/error.dart';

/// Mensagem por tipo de [Failure] ao ler o detalhe de uma versão (T3, item
/// 50) — compartilhada entre `VersionReviewFailureView` (erro dentro do
/// diálogo de revisão) e o aviso de `Carregar no rascunho` (erro antes de
/// abrir qualquer diálogo).
String versionFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
  NotFoundFailure() => 'Esta versão não existe mais.',
  ConflictFailure(message: final m) => m,
  ValidationFailure(message: final m) => m,
  UnexpectedFailure() => 'Não foi possível carregar esta versão.',
};
