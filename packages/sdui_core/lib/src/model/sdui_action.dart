import 'package:equatable/equatable.dart';

class SduiAction extends Equatable {
  const SduiAction({required this.type, this.params = const {}});

  factory SduiAction.fromJson(Map<String, dynamic> json) => SduiAction(
    type: (json['action'] ?? json['type'] ?? '').toString(),
    params: (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  final String type;
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() => {
    'action': type,
    if (params.isNotEmpty) 'params': params,
  };

  @override
  List<Object?> get props => [type, params];
}
