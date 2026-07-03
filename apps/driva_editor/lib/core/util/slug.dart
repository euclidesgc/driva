/// Derivação e validação de slug — Dart puro, sem Flutter, testável isolado.
///
/// O slug é a referência técnica do conteúdo (`^[a-z][a-z0-9-]*$`), única por
/// projeto. O editor deriva-o do nome ao vivo e sugere uma variante livre em
/// colisão (`home` → `home-2`). A garantia dura de unicidade é do Postgres; o
/// que mora aqui é a boa sugestão local.
class SlugUtil {
  const SlugUtil._();

  static final RegExp _valid = RegExp(r'^[a-z][a-z0-9-]*$');
  static final RegExp _nonSlugChar = RegExp('[^a-z0-9]+');
  static final RegExp _dashRuns = RegExp('-+');
  static final RegExp _leadingNonLetter = RegExp('^[^a-z]+');
  static final RegExp _trailingDash = RegExp(r'-+$');

  static const Map<String, String> _diacritics = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// `true` quando [slug] já está no formato canônico aceito pelo kernel.
  static bool isValid(String slug) => _valid.hasMatch(slug);

  /// Normaliza um texto livre para o formato `^[a-z][a-z0-9-]*$`.
  /// Pode devolver string vazia (ex.: nome só com símbolos) — o chamador trata.
  static String slugify(String input) {
    final lowered = input.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final char in lowered.split('')) {
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(_nonSlugChar, '-')
        .replaceAll(_dashRuns, '-')
        .replaceAll(_leadingNonLetter, '')
        .replaceAll(_trailingDash, '');
  }

  /// Sugere um slug livre a partir de [base], evitando os já usados em [taken].
  /// Se [base] não for canônico, é normalizado antes. Em colisão, sufixa
  /// incremental por projeto: `home` → `home-2` → `home-3`.
  static String suggestFree(String base, Set<String> taken) {
    final root = isValid(base) ? base : slugify(base);
    if (root.isEmpty) return root;
    if (!taken.contains(root)) return root;
    var suffix = 2;
    while (taken.contains('$root-$suffix')) {
      suffix++;
    }
    return '$root-$suffix';
  }
}
