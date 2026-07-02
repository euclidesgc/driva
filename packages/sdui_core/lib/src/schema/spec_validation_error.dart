import 'package:equatable/equatable.dart';

/// Erro de validação de um spec: o JSON não tem a forma esperada.
///
/// É o "Failure" do kernel. O app traduz para a sua `Failure` de domínio
/// (ex.: `ValidationFailure`) na camada data.
class SpecValidationError extends Equatable {
  const SpecValidationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'SpecValidationError: $message';
}
