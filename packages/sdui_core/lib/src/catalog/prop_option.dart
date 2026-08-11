import 'package:equatable/equatable.dart';

class PropOption extends Equatable {
  const PropOption(this.value, {this.label, this.iconName});

  final String value;

  final String? label;

  /// Nome simbólico resolvido pelo editor; permite editar o enum como grupo de
  /// ícones em vez de dropdown.
  final String? iconName;

  String get displayLabel => label ?? value;

  @override
  List<Object?> get props => [value, label, iconName];
}
