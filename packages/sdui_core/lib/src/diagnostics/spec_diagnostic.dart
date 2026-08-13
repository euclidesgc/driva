import 'package:equatable/equatable.dart';

enum DiagnosticSeverity { error, warning }

/// [flexOnlyOutsideFlex] é o único caso em que o renderer desiste de desenhar
/// o nó; [emptySingleSlot] desenha, só não produz pixel algum.
enum DiagnosticCode { flexOnlyOutsideFlex, emptySingleSlot }

/// Problema estrutural de um nó do documento, apontado sem impedir a edição:
/// o editor deixa o usuário soltar o widget onde quiser e lista aqui o que
/// ficou fora do lugar.
class SpecDiagnostic extends Equatable {
  const SpecDiagnostic({
    required this.nodeId,
    required this.nodeType,
    required this.code,
    required this.severity,
    required this.message,
  });

  final String nodeId;
  final String nodeType;
  final DiagnosticCode code;
  final DiagnosticSeverity severity;
  final String message;

  @override
  List<Object?> get props => [nodeId, nodeType, code, severity, message];
}
