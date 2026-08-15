import 'package:equatable/equatable.dart';

/// Erro esperado, o que a UI sabe tratar. `sealed` para o `switch` ser
/// exaustivo; a hierarquia inteira mora neste arquivo porque o Dart exige
/// subtipos de `sealed` na mesma biblioteca.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Falha de comunicação com o servidor.',
  ]);
}

/// Payload fora do formato esperado — envelope da API ou o próprio spec
/// recusado pelo kernel.
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Conteúdo inválido.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Conteúdo não encontrado.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
