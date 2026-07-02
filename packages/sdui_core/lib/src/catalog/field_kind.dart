/// Tipos de campo que o Inspector do editor sabe renderizar
/// (`kind → widget de edição`). Adicionar um kind = um editor novo no editor.
enum FieldKind {
  string,
  doubleNum,
  intNum,
  boolean,

  /// Cor em hex `#RRGGBB` ou `#AARRGGBB`.
  color,

  /// Seleção entre [PropField.enumValues].
  enumeration,

  /// `{all}` | `{horizontal, vertical}` | `{left, top, right, bottom}`.
  edgeInsets,

  /// Um dos 9 pontos de `Alignment` (`topLeft` ... `bottomRight`).
  alignment,

  /// Nome de ícone do catálogo curado de Material Icons do renderer.
  iconName,
}
