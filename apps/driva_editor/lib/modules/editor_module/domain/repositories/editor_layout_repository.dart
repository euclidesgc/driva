import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';

/// D11: pilha própria do `editor_module`, formato do `EditorRepository` que
/// já existe aqui — não do `preferences_module` (genérico, não conhece o
/// editor).
///
/// D12: ausência cai em [EditorLayoutSnapshot] padrão dentro de `Right` — a
/// camada `data` resolve isso sozinha. `Left` fica reservado para o que ela
/// não recupera sem ajuda (ex.: JSON corrompido) — quem lê o resultado decide
/// se dobra para o padrão ou propaga, nunca este contrato.
abstract interface class EditorLayoutRepository {
  Future<Either<Failure, EditorLayoutSnapshot>> getLayout();

  Future<Either<Failure, Unit>> saveLayout(EditorLayoutSnapshot layout);
}
