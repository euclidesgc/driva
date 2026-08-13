import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart' show ContentSpec;

/// Um passo do histórico: o documento **antes** da mutação, com a seleção que
/// existia junto dele. Restaurar só o documento deixaria o Inspector apontando
/// para um nó que a árvore antiga não tem.
class EditorHistoryEntry extends Equatable {
  const EditorHistoryEntry({
    required this.document,
    this.selectedNodeId,
    this.coalesceKey,
  });

  final ContentSpec document;
  final String? selectedNodeId;

  /// Mutações consecutivas com a mesma chave colapsam numa entrada só — sem
  /// isso, digitar no Inspector geraria um desfazer por tecla.
  final String? coalesceKey;

  @override
  List<Object?> get props => [document, selectedNodeId, coalesceKey];
}
