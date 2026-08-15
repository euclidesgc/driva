import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice_kind.dart';
import 'package:equatable/equatable.dart';

/// [sequence] entra na igualdade de propósito: repetir o mesmo arraste inválido
/// tem de emitir um estado novo, senão a barra de status não reage à segunda
/// tentativa.
class EditorNotice extends Equatable {
  const EditorNotice({
    required this.kind,
    required this.sequence,
    this.subjectType,
    this.wrapperType,
  });

  final EditorNoticeKind kind;
  final int sequence;

  /// Tipo do widget que recusou receber o nó, quando há um.
  final String? subjectType;

  /// Tipo do contêiner criado pelo kernel em [EditorNoticeKind.dropWrapped] —
  /// carregado até aqui para a mensagem não hardcodar o rótulo enquanto o
  /// kernel só devolve `'column'`.
  final String? wrapperType;

  @override
  List<Object?> get props => [kind, sequence, subjectType, wrapperType];
}
