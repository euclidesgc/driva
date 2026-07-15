import 'package:equatable/equatable.dart';

class SpecValidationError extends Equatable {
  const SpecValidationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'SpecValidationError: $message';
}
