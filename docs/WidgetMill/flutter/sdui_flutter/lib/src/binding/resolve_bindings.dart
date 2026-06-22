/// Resolve referências de binding e tokens num documento de spec (JSON),
/// produzindo uma cópia com os valores substituídos.
///
/// - `"{{chave}}"` → `data['chave']` (spec §1.3)
/// - `"$nome"`     → `tokens['nome']` (design system, spec §5)
///
/// Não resolvido → mantém o literal (facilita diagnóstico no preview).
/// Passe puro e recursivo: não toca nos builders.

final RegExp _binding = RegExp(r'^\{\{\s*([\w.]+)\s*\}\}$');
final RegExp _token = RegExp(r'^\$([\w.]+)$');

Map<String, dynamic> resolveBindings(
  Map<String, dynamic> json, {
  Map<String, dynamic> data = const {},
  Map<String, dynamic> tokens = const {},
}) {
  return _resolve(json, data, tokens) as Map<String, dynamic>;
}

Object? _resolve(
  Object? value,
  Map<String, dynamic> data,
  Map<String, dynamic> tokens,
) {
  if (value is String) {
    final binding = _binding.firstMatch(value);
    if (binding != null) {
      final key = binding.group(1)!;
      return data.containsKey(key) ? data[key] : value;
    }
    final token = _token.firstMatch(value);
    if (token != null) {
      final key = token.group(1)!;
      return tokens.containsKey(key) ? tokens[key] : value;
    }
    return value;
  }
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _resolve(entry.value, data, tokens),
    };
  }
  if (value is List) {
    return [for (final item in value) _resolve(item, data, tokens)];
  }
  return value;
}
