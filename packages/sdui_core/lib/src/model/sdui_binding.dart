/// Binding é **dado**, não execução: o editor só escreve e lê a expressão
/// `{{...}}`; quem resolve o valor é o app cliente.
abstract final class SduiBinding {
  /// O miolo tem de começar e terminar em não-espaço: sem isso `{{   }}`
  /// casaria, gravando um binding que não aponta para lugar nenhum.
  static final _pattern = RegExp(
    r'^\{\{\s*(\S(?:.*\S)?)\s*\}\}$',
    dotAll: true,
  );

  static bool isBinding(Object? value) =>
      value is String && _pattern.hasMatch(value);

  /// A expressão sem as chaves, ou `null` se [value] não for um binding.
  static String? expressionOf(Object? value) =>
      value is String ? _pattern.firstMatch(value)?.group(1) : null;

  /// `null` para expressão vazia — o chamador remove a chave em vez de gravar
  /// um binding que não aponta para lugar nenhum.
  static String? wrap(String expression) {
    final trimmed = expression.trim();
    return trimmed.isEmpty ? null : '{{$trimmed}}';
  }
}
