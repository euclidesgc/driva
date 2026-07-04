import 'package:equatable/equatable.dart';

/// Domain failure: the *expected* error, the one the UI knows how to handle.
///
/// Sealed so every `switch` over failures is exhaustive. The whole hierarchy
/// lives in this file because Dart requires sealed subtypes in the same
/// library.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Human-readable description (pt-BR), safe to show to the user.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Connectivity or server-side error (timeouts, 5xx, no connection).
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Falha de comunicação com o servidor.',
  ]);
}

/// Payload that does not match the expected schema (zard `safeParse` failed)
/// or a 400 rejected by the backend.
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Dados inválidos.']);
}

/// The requested resource does not exist (404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

/// Slug already taken within the project (backend `409`). Carries an optional
/// free-slug suggestion; the UI falls back to a local suggestion when absent.
final class ConflictFailure extends Failure {
  const ConflictFailure({
    this.suggestedSlug,
    String message = 'Esse slug já está em uso neste projeto.',
  }) : super(message);

  final String? suggestedSlug;

  @override
  List<Object?> get props => [message, suggestedSlug];
}

/// Anything that escaped the typed cases — the honest "we did not foresee it".
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
