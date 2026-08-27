/// Motivo pelo qual `DrivaContentRepository.load` não conseguiu servir
/// nenhum conteúdo — nem memória, nem disco, nem rede, nem fallback
/// embarcado.
enum DrivaLoadCause {
  /// O `http.Client` lançou ao tentar alcançar o servidor (sem conexão,
  /// DNS, timeout etc.) — nunca chegou a existir uma resposta HTTP.
  network,

  /// O servidor respondeu 404: chave publicável inválida ou slug sem
  /// publicação. As duas causas não são distinguíveis por design — decisão
  /// de segurança da fatia 1, para não dar a quem sonda de fora um jeito de
  /// separar "chave errada" de "conteúdo inexistente".
  notFound,

  /// O corpo da resposta não virou um `ContentSpec` válido: JSON
  /// indecodificável, envelope sem `spec`, ou `parseContentSpec` devolvendo
  /// `Left` — inclusive quando `specVersion` é mais novo que o suportado
  /// pelo app instalado.
  invalidSpec,

  /// Qualquer outro status HTTP além de 200 e 304.
  serverError,
}

/// Falha ao carregar o conteúdo de `slug`: nenhuma fonte serviu nada — sem
/// cache em memória, sem cache em disco, sem resposta 200 válida do
/// servidor e sem fallback embarcado. Fecha o canal de erro do
/// `Stream<ContentSpec>` de `DrivaContentRepository.load` quando isso
/// acontece; quando cache ou fallback conseguem servir algo, esta exceção
/// nunca é emitida.
class DrivaLoadFailure implements Exception {
  const DrivaLoadFailure({required this.slug, required this.cause});

  /// O slug que estava sendo carregado.
  final String slug;

  /// Por que nenhuma fonte serviu conteúdo para [slug].
  final DrivaLoadCause cause;

  @override
  String toString() => 'DrivaLoadFailure(slug: $slug, cause: $cause)';
}
