import 'package:equatable/equatable.dart';

/// Um ponto de trabalho marcado pelo autor ao salvar — o "commit" do editor.
///
/// Não tem número de versão de propósito: `vN` é o que o usuário lê como "no
/// ar (v3)" e só publicação o consome. Um checkpoint se identifica pela nota
/// e pela data, e nunca foi ao ar.
class ContentCheckpoint extends Equatable {
  const ContentCheckpoint({
    required this.id,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final String id;
  final DateTime createdAt;
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [id, createdAt, note, createdBy];
}
