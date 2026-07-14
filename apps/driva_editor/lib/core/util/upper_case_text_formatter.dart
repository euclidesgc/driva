import 'package:flutter/services.dart';

/// Formatter de campo de texto que força maiúsculas a cada edição. Genérico
/// (não é widget) — usado pelo editor de propriedades e disponível a qualquer
/// campo que precise de entrada em caixa alta.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
