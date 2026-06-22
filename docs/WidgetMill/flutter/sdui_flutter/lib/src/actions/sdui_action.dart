/// Uma ação a ser executada (spec §4): tipo + params.
class SduiAction {
  const SduiAction(this.type, this.params);

  factory SduiAction.fromJson(Map<String, dynamic> json) => SduiAction(
        json['type'] as String,
        (json['params'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  final String type;
  final Map<String, dynamic> params;
}

/// Handler fornecido pelo host: executa cada ação (navigate, openUrl, track...).
typedef SduiActionHandler = void Function(SduiAction action);
